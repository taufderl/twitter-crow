class AddFieldsToSetting < ActiveRecord::Migration
  def change
    add_column :settings, :key, :string
    add_column :settings, :value, :string
    add_column :settings, :description, :string
  end
end
