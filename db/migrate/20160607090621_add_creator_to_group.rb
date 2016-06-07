class AddCreatorToGroup < ActiveRecord::Migration[5.0]
  def change
    add_column :groups, :creator, :integer
  end
end