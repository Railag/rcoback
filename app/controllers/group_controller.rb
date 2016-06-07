class GroupController < ApplicationController
  protect_from_forgery except: [:create, :fetch]

  def create
    begin
      @new_group = Group.create(permitted_params)

      render json: group_response(@new_group)
    rescue ActiveRecord::RecordNotUnique
      render json: t(:group_create_exists)
    end
  end

  def fetch
    @groups = Group.where(creator: permitted_params[:creator])

    if @groups.blank?
      render json: t(:group_fetch_error)
    else
      render json: group_response(@groups)
    end
  end

  def add_user

    @user = User.find_by(login: params_for_add_user_to_group[:user_login_or_email])

    @group = Group.find_by(id: params_for_add_user_to_group[:group_id])

    @group.users.create(@user)

    # TODO create PN and send email for this user with join/reject options for invitation

    render json: t(:group_add_user_success)
  end

  private
  def group_response(group)
    group.as_json(:only => [:id, :title, :creator])
  end

  private
  def permitted_params
    params.permit(:title, :creator)
  end

  private
  def params_for_add_user_to_group
    params.permit(:user_login_or_email, :group_id)
  end

end