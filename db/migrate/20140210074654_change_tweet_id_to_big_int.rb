class ChangeTweetIdToBigInt < ActiveRecord::Migration
  def change
    if Rails.env.production?
      change_column :tweets, :id , "BIGINT UNSIGNED NOT NULL AUTO_INCREMENT"
    end
  end
end
