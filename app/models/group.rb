class Group < ApplicationRecord
  has_many :group_users
  has_many :messages

  def self.get_user_groups(user_id)
    # TODO optimize db calls
    groups_owner = Group.where(user_id: user_id)

    groups_ids = GroupUser.where(user_id: user_id).map(&:group_id)
    groups_member = Group.where(id: groups_ids)

    groups = groups_owner + groups_member
  end
end
