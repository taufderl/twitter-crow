class AddClusterToTweet < ActiveRecord::Migration
  def change
    add_column :tweets, :cluster, :integer
  end
end
