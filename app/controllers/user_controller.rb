class UserController < ApplicationController
  include BCrypt

  protect_from_forgery except: [:create, :login, :startup_login]

  before_action :generate_authentication_token, only: :create
  before_action :encrypt_password, only: :create

  def get
    @users = User.all

    render json: @users
  end

  def create
    @new_user = User.create(permitted_params)

    render json: user_response(@new_user)
  end

  def login #password
    if params[:password].blank?
      render json: "{'error': 'not_found'}"
    end

    @user = User.find_by(password: pass(params[:password]))

    render json: user_response(@user)
  end

  def startup_login # token
    if params[:token].blank?
      render json: "{'error': 'not_found'}"
    end

    @user = User.find_by(token: params[:token])

    render json: user_response(@user)
  end

  private
  def user_response(user)
    user.as_json(:only => [:login, :token, :email])
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
