class AddLastUpdateToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_update, :timestamp
  end
end
