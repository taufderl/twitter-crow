class CreateMutualInformations < ActiveRecord::Migration
  def change
    create_table :mutual_informations do |t|
      t.references :user, index: true, unique: true
      t.text :content

      t.timestamps
    end
  end
end
