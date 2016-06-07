class AddIndexToGroup < ActiveRecord::Migration[5.0]
  def change
    add_index :groups, :title, unique: true
  end
end