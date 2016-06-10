class UserController < ApplicationController
  include BCrypt

  protect_from_forgery except: [:create, :login, :startup_login, :fcm_token, :send_pn]

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

    user = User.find_by(password: pass(params[:password]))

    if user.blank?
      render json: t(:user_login_not_found_error)
    else
      render json: user_response(user)
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

  def send_pn
    fcm = FCM.new('AIzaSyCIaz5C9ertmcJ9DldIVMj7eTTsR6legRA', sender)
    # you can set option parameters in here
    #  - all options are pass to HTTParty method arguments
    #  - ref: https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb#L29-L60
    #  fcm = FCM.new("my_api_key", timeout: 3)

    registration_ids= ["duK2HDhnakg%3AAPA91bECzkTcBNjnUe4PRJlcIjFE87DEiCkqxoOe2lFpBP2luc2MTPkKU13s08FBHXifObh96n2-Ur92dHp4k3DSgY5QF4mvXLvSIHma4cjYewPQM71-3YpMSENYX90v-F9nlH1u8-rF",
                       "13"] # an array of one or more client registration tokens
    options = {data: {score: "123"}, collapse_key: "updated_score"}
    response = fcm.send(registration_ids, options)
    Rails.logger = Logger.new(STDOUT)
    logger.info(response)

    render json: t(:pn_send_success)
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
  def pass(pass)
    Password.create(pass).to_str
  end

  private
  def generate_authentication_token
    loop do
      params[:token] = SecureRandom.base64(64)
      break unless User.find_by(token: params[:token])
    end
  end

end