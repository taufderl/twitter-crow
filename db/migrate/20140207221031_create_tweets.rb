class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.timestamp :created_at
      t.text :text
      t.string :screen_name
      t.float :geo_longitude
      t.float :geo_latitude

      t.timestamps
    end
  end
end
