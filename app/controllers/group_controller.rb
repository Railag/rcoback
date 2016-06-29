class GroupController < ApplicationController
  protect_from_forgery except: [:create, :fetch, :fetch_users, :fetch_messages, :send_message, :start_call, :invite_to_call, :add_user, :add_invite_user]

  # PN codes
  PN_GROUP_INVITE = 1
  PN_GROUP_CALL = 2

  def create
    begin
      new_group = Group.create(permitted_params)

      render json: group_response(new_group)
    rescue ActiveRecord::RecordNotUnique
      render json: t(:group_create_exists)
    end
  end

  def fetch
    user_id = permitted_params[:user_id]
    groups = Group.get_user_groups(user_id)

    if groups.blank?
      render json: t(:group_fetch_error)
    else
      render json: {groups: group_response(groups)}
    end
  end

  def add_invite_user
    group_id = params_for_add_user_invite[:group_id]
    group = Group.find_by(id: group_id)

    login = params_for_add_user_invite[:user_login_or_email]
    user = User.find_by(login: login)

    if user.blank? # TODO add email user search
      render json: t(:group_add_user_no_user)
      return
    end

    existing_user = GroupUser.find_by(user_id: user.id, group_id: group_id)
    if existing_user.blank?
      registration_id = User.where(id: user.id).map(&:fcm_token)

      title = "Join #{group.title}!"

      options = {notification: {title: title}, data: {group: group.title, data: group.id.to_s, code: PN_GROUP_INVITE}, collapse_key: 'invite_group_pn'}

      send_pns(registration_id, options)

      InviteMailer.invite_email(user).deliver_now

      render json: t(:group_add_user_invite_success)
    else
      render json: t(:group_add_user_error)
    end

    # TODO create PN and send email for this user with join/reject options for invitation
  end

  def add_user
    user_id = params_for_add_user[:user_id]
    group_id = params_for_add_user[:group_id]

    # TODO verify
    invite_token = params_for_add_user[:invite_token]

    group = Group.find_by(id: group_id)

    group_user = GroupUser.create(user_id: user_id, group_id: group_id)
    group.group_users << group_user
    render json: t(:group_add_user_success)
  end

  def remove_user
    group_id = params_for_remove_user[:group_id]

    login = params_for_remove_user[:login]
    if login.blank?
      render json: t(:group_add_user_no_user)
      return
    end

    user = User.find_by(login: login)

    existing_user = GroupUser.find_by(user_id: user.id, group_id: group_id)
    if existing_user.present?
      group_user = GroupUser.find_by(user_id: user.id, group_id: group_id)
      group_user.destroy
      render json: t(:group_remove_user_success)
    else
      render json: t(:group_remove_user_error)
    end
  end

  def fetch_users
    group = Group.find_by(id: params[:group_id])

    group_users = group.group_users

    users = []

    group_users.each do |gu|
      users << User.find_by(id: gu.user_id)
    end

    render json: users.as_json(:only => [:id, :login])

  end

  def fetch_messages
    group = Group.find_by(id: params[:group_id])

    group_messages = group.messages

    json = []

    group_messages.each do |gm|
      user = User.find_by(id: gm.user_id)
      json << {group_id: group.id, user_id: user.id, user_login: user.login, user_image_url: user.login, message: gm.text, date: gm.created_at} # TODO image url
    end

    render json: json
  end

  def send_message
    # TODO check if user is member of group

    message = Message.create(message_params)

    group = Group.find_by(id: params[:group_id])

    group.messages << message

    render json: t(:group_send_message_success)
  end

  def start_call
    creator_id = start_call_params[:user_id]

    group = Group.find_by(user_id: creator_id)

    if group.blank?
      render json: t(:group_pn_error_no_group)
      return
    end

    # start Node.js signalling server
    port = get_free_port
    if port.blank?
      render json: t(:group_port_busy_error)
      return
    end

    #fork { exec("set PORT=#{port} & forever start ./webrtc-server/app.js") }

    # TODO handle pid
    pid = spawn "set PORT=#{port} & start forever start ./webrtc-server/app.js"

    ip = Socket.ip_address_list.detect(&:ipv4_private?).try(:ip_address)

    render json: "{\"host\":\"http://#{ip}:#{port}\"}"

  end

  def get_free_port

    3001.upto(3100) do |port|
      puts port
      result = `netstat -na | findstr "port"`
      if result.blank?
        return port
      end

    end
  end

  def invite_to_call
    creator_id = invite_to_call_params[:user_id]

    group = Group.find_by(user_id: creator_id)

    if group.blank?
      render json: t(:group_pn_error_no_group)
      return
    end

    group_users_ids = group.group_users.map(&:user_id)

    registration_ids = User.where(id: group_users_ids).map(&:fcm_token)

    title = "Join #{group.title} call!"

    # host#caller_id
    body = invite_to_call_params[:socket_address] + '#' + invite_to_call_params[:call_id]

    options = {notification: {title: title, body: body}, data: {group: group.title, data: body, code: PN_GROUP_CALL}, collapse_key: 'invite_call_pn'}

    send_pns(registration_ids, options)

    render json: t(:pn_send_success)
  end

  def send_pns(registration_ids, options)
    fcm = FCM.new(t(:fcm_key))

    response = fcm.send(registration_ids, options)

    Rails.logger = Logger.new(STDOUT)
    logger.info(response)

    #  render json: t(:pn_send_success)
  end

  private
  def start_call_params
    params.permit(:user_id)
  end

  private
  def invite_to_call_params
    params.permit(:user_id, :socket_address, :call_id)
  end

  private
  def message_params
    params.permit(:group_id, :user_id, :text)
  end

  private
  def group_response(group)
    group.as_json(:only => [:id, :title, :user_id])
  end

  private
  def permitted_params
    params.permit(:title, :user_id)
  end

  private
  def params_for_add_user_invite
    params.permit(:user_login_or_email, :group_id)
  end

  private
  def params_for_add_user
    params.permit(:user_id, :group_id, :invite_token)
  end

  private
  def params_for_remove_user
    params.permit(:login, :group_id)
  end

end