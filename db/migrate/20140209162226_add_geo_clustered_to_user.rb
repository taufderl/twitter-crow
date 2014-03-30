class AddGeoClusteredToUser < ActiveRecord::Migration
  def change
    add_column :users, :geo_clustered, :timestamp
  end
end
