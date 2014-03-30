class AddGeoEnabledToTweets < ActiveRecord::Migration
  def change
    add_column :tweets, :geo_enabled, :boolean
  end
end
  