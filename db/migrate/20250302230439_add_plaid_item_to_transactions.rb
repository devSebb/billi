class AddPlaidItemToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_reference :transactions, :plaid_item, foreign_key: true, null: true
  end
end
