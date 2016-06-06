class User < ApplicationRecord
  include BCrypt

  has_many :groups
  has_many :messages

  def password
    @password ||= Password.new(@password)
  end
end
