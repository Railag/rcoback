class UserController < ApplicationController
  include BCrypt

  protect_from_forgery except: :create

  before_action :generate_authentication_token, only: :create
  before_action :encrypt_password, only: :create

  def get
    @users = User.all

    render json: @users
  end

  def create
    @new_user = User.create(permitted_params)

    render json: @new_user.as_json(:only => [:login, :token])
  end

  private
  def encrypt_password
      params[:user][:password] = Password.create(params[:user][:password]).to_str
  end

  private
  def permitted_params
    params.require(:user).permit(:login, :password, :email, :token)
  end

  def generate_authentication_token
    loop do
      params[:user][:token] = SecureRandom.base64(64)
      break unless User.find_by(token: params[:user][:token])
    end
  end

end
