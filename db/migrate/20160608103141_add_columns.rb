class AddColumns < ActiveRecord::Migration[5.0]
  def change
    rename_column :groups, :creator, :user_id
    add_column :messages, :user_id, :integer
    add_column :messages, :group_id, :integer
  end
end
