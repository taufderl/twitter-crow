class AddTotalToMutualInformation < ActiveRecord::Migration
  def change
    add_column :mutual_informations, :total, :float
  end
end
