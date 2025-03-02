class CreateTempCsvData < ActiveRecord::Migration[7.2]
  def change
    create_table :temp_csv_data do |t|
      t.references :user, null: false, foreign_key: true
      t.json :headers
      t.json :data
      t.timestamps
    end
  end
end
