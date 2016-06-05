class UserController < ApplicationController
  protect_from_forgery except: :create

  def get
    @users = User.all

    render json: @users
  end

  def create
    @new_user = User.create(permitted_params)
  #  @new_user.save!

    render json: @new_user
  end

  private
  def permitted_params
    params.require(:user).permit(:login, :password, :email)
  end

end
