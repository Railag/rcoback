class AddFcmTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :fcm_token, :string
  end
end