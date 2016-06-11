class User < ApplicationRecord
  include BCrypt

  has_many :groups
  has_many :group_users
end
