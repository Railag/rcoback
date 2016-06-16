class UserController < ApplicationController
  include BCrypt

  protect_from_forgery except: [:create, :login, :startup_login, :fcm_token, :send_pns_to_everyone, :send_pns_to_group]

  before_action :generate_authentication_token, only: :create
  before_action :encrypt_password, only: :create

  def get
    users = User.all

    render json: users
  end

  def create
    begin
      new_user = User.create(permitted_params)
      render json: user_response(new_user)
    rescue ActiveRecord::RecordNotUnique
      render json: t(:user_login_exists_error)
    end
  end

  def login #password
    if params[:password].blank?
      render json: t(:user_login_not_found_error)
      return
    end

    user = User.find_by(login: login_params[:login])

    if user.blank?
      render json: t(:user_login_not_found_error)
    else
      stored_hash = BCrypt::Password.new(user.password)
      if stored_hash == login_params[:password]
        render json: user_response(user)
      else
        render json: t(:user_login_not_found_error)
      end
    end
  end

  def startup_login # token
    if params[:token].blank?
      render json: t(:user_login_not_found_error)
      return
    end

    user = User.find_by(token: params[:token])

    if user.blank?
      render json: t(:user_login_not_found_error)
    else
      render json: user_response(user)
    end
  end

  def fcm_token
    user_id = fcm_token_params[:user_id]
    fcm_token = fcm_token_params[:fcm_token]

    user = User.find_by(id: user_id)

    if user.present?
      user[:fcm_token] = fcm_token
      user.save!
      render json: t(:user_fcm_token_success)
    else
      render json: t(:user_fcm_token_error)
    end
  end

  def send_pns(registration_ids, options)
    fcm = FCM.new(t(:fcm_key))

    response = fcm.send(registration_ids, options)

    Rails.logger = Logger.new(STDOUT)
    logger.info(response)

    render json: t(:pn_send_success)
  end

  def send_pns_to_everyone
    # you can set option parameters in here
    #  - all options are pass to HTTParty method arguments
    #  - ref: https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb#L29-L60
    #  fcm = FCM.new("my_api_key", timeout: 3)

    user_id = pn_params[:user_id]
    title = pn_params[:title]
    text = pn_params[:text]

    user = User.find_by(id: user_id)

    if user.blank?
      render json: t(:user_pn_error_no_user)
      return
    end

    registration_ids = fetch_all_fcm_tokens
    #registration_ids= [
    #    'cidPybiorOw:APA91bFz7x9RC2RbcC4AAeu9mtw1ganMk92beXjVZ5IghquG8-Jc5C1wiQTq4-aM0pWWEfXqoXMYaXy36tyPESBISVcGl17X_hduR5Otoejtn2_D9_eQBdkooaYuRQmjNJW9VhabVdUk'] # an array of one or more client registration tokens

    options = {notification: {title: title, body: text}, data: {user: user.login}, collapse_key: "test_pn"}

    send_pns(registration_ids, options)
  end

  def send_pns_to_group
    group_id = group_pn_params[:group_id]
    title = pn_params[:title]
    text = pn_params[:text]

    group = Group.find_by(id: group_id)

    if group.blank?
      render json: t(:group_pn_error_no_group)
      return
    end

    group_users_ids = group.group_users.map(&:user_id)

    registration_ids = User.where(id: group_users_ids).map(&:fcm_token)

    options = {notification: {title: title, body: text}, data: {group: group.name}, collapse_key: "group_pn"}

    send_pns(registration_ids, options)
  end

  private
  def fetch_all_fcm_tokens
    User.select(:fcm_token).map(&:fcm_token)
  end

  private
  def pn_params # TODO more params
    params.permit(:user_id, :title, :text)
  end

  private
  def group_pn_params
    params.permit(:group_id, :title, :text)
  end

  private
  def fcm_token_params
    params.permit(:user_id, :fcm_token)
  end

  private
  def user_response(user)
    user.as_json(:only => [:id, :idd, :login, :token, :email])
  end

  private
  def permitted_params
    params.permit(:login, :password, :email, :token)
  end

  private
  def encrypt_password
    params[:password] = Password.create(params[:password]).to_str
  end

  private
  def generate_authentication_token
    loop do
      params[:token] = SecureRandom.base64(64)
      break unless User.find_by(token: params[:token])
    end
  end

  private
  def login_params
    params.permit(:login, :password)
  end

end