class UserProfileController < ApplicationController
  include TransactionFilterable
  include Pagy::Backend
  before_action :authenticate_user!

  def show
    @user = current_user
    @plaid_items = @user.plaid_items
    @analysis_sessions = @user.analysis_sessions.order(created_at: :desc)
    # Add statistics calculations
    base_transactions = @user.transactions

    @total_transactions = base_transactions.count
    @total_spent = base_transactions.where("amount > 0").sum(:amount)
    @average_transaction = base_transactions.where("amount > 0").average(:amount)
    @upload_count = @user.analysis_sessions.count + @user.plaid_items.count
    @payments = base_transactions.where("amount < 0").where(category: "Payment").sum(:amount).abs
    @credit_transactions = base_transactions.where(category: "Credit").sum(:amount)
    @income_transactions = -base_transactions.where("amount < 0").where.not(category: [ "Payment", "Credit" ]).sum(:amount)
    @expense_transactions = base_transactions.where("amount > 0").sum(:amount)
    @net_worth = (@income_transactions - @expense_transactions - @credit_transactions)
    @cash_on_hand = base_transactions.where("amount < 0 AND category = ?", "Cash on Hand").sum(:amount).abs
    @investments = base_transactions.where("amount < 0 AND category = ?", "Investments").sum(:amount).abs
    @salary = base_transactions.where("amount < 0 AND category = ?", "Salary").sum(:amount).abs
    @assets = @cash_on_hand + @investments + @salary
    @countries_spent = base_transactions.where("amount > 0").distinct.count(:country)
  end
end
