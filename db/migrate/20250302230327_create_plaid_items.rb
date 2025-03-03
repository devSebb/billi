class CreatePlaidItems < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token

      t.timestamps
    end
  end
end
