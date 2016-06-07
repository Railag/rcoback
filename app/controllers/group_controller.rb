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
      render json: @groups
    end
  end

  private
  def group_response(group)
    group.as_json(:only => [:id, :title, :creator])
  end

  private
  def permitted_params
    params.permit(:title, :creator)
  end

end
