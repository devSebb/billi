class CreateAnalysisSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :analysis_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
