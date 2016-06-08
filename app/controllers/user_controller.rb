class UserController < ApplicationController
  include BCrypt

  protect_from_forgery except: [:create, :login, :startup_login]

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
