class RenameUserUpdateColumn < ActiveRecord::Migration
  def change
    rename_column :users, :last_update, :tweets_updated
  end
end
