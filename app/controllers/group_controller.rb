class GroupController < ApplicationController
  protect_from_forgery except: [:create, :fetch, :fetch_users, :fetch_messages, :send_message]
  #require 'fcm'

  def create
    begin
      new_group = Group.create(permitted_params)

      render json: group_response(new_group)
    rescue ActiveRecord::RecordNotUnique
      render json: t(:group_create_exists)
    end
  end

  def fetch
    groups = Group.where(user_id: permitted_params[:creator])

    if groups.blank?
      render json: t(:group_fetch_error)
    else
      render json: group_response(groups)
    end
  end

  def add_user
    group_id = params_for_add_user[:group_id]
    group = Group.find_by(id: group_id)

    login = params_for_add_user[:user_login_or_email]
    user = User.find_by(login: login)

    if user.blank? # TODO add email user search
      render json: t(:group_add_user_no_user)
      return
    end

    existing_user = GroupUser.find_by(user_id: user.id, group_id: group_id)
    if existing_user.blank?
      group_user = GroupUser.create(user_id: user.id, group_id: group_id)
      group.group_users << group_user
      render json: t(:group_add_user_success)
    else
      render json: t(:group_add_user_error)
    end

    # TODO create PN and send email for this user with join/reject options for invitation
  end

  private
  def send_pn
    fcm = FCM.new("my_api_key")
    # you can set option parameters in here
    #  - all options are pass to HTTParty method arguments
    #  - ref: https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb#L29-L60
    #  fcm = FCM.new("my_api_key", timeout: 3)

    registration_ids= ["12", "13"] # an array of one or more client registration tokens
    options = {data: {score: "123"}, collapse_key: "updated_score"}
    response = fcm.send(registration_ids, options)
    test = []
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

    # TODO create PN and send email for this user with join/reject options for invitation
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

  def message_params
    params.permit(:group_id, :user_id, :text)
  end

  private
  def group_response(group)
    group.as_json(:only => [:id, :title, :user_id])
  end

  private
  def permitted_params
    params.permit(:title, :creator)
  end

  private
  def params_for_add_user
    params.permit(:user_login_or_email, :group_id)
  end

  private
  def params_for_remove_user
    params.permit(:login, :group_id)
  end

end