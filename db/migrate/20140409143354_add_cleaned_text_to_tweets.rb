class AddCleanedTextToTweets < ActiveRecord::Migration
  def change
    add_column :tweets, :text_cleaned, :string
  end
end
