class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :currency
      t.string :country
      t.string :category
      t.string :merchant
      t.datetime :transaction_date

      t.timestamps
    end
  end
end
