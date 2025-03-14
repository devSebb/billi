class HomeController < ApplicationController
  include TransactionFilterable
  include Pagy::Backend

  def index
    if user_signed_in?
      base_transactions = Current.user.transactions

      # Calculate stats from all transactions
      @total_transactions = base_transactions.count
      @total_spent = base_transactions.where("amount > 0").sum(:amount)
      @average_transaction = base_transactions.where("amount > 0").average(:amount)
      @upload_count = Current.user.analysis_sessions.count + Current.user.plaid_items.count
      @payments = base_transactions.where("amount < 0").sum(:amount).abs

      # Net Worth calculation
      # Get all income (negative numbers in DB)
      income_transactions = base_transactions.where("amount < 0").sum(:amount)
      # Get all expenses (positive numbers in DB)
      expense_transactions = base_transactions.where("amount > 0").sum(:amount)
      # Net worth = absolute value of (income + expenses)
      # Since income is negative and expenses positive, adding them gives us the negative net worth if expenses > income
      @net_worth = (income_transactions + expense_transactions)

      @top_category = base_transactions
        .where("amount > 0")
        .group(:category)
        .sum(:amount)
        .max_by { |_, amount| amount }
        &.first

      @cash_on_hand = base_transactions
        .where(category: "Cash on Hand")
        .sum(:amount)
        .abs

      @assets = base_transactions
        .where("amount < 0 AND category IN (?)", [ "Cash on Hand", "Investments", "Salary" ])
        .sum(:amount)
        .abs

      @countries_spent = base_transactions
        .where("amount > 0")
        .distinct
        .count(:country)

      # Apply sorting and pagination
      sorted_transactions = sort_transactions(base_transactions)
      @pagy, @transactions = pagy(sorted_transactions)

      # For charts
      @chart_data = base_transactions.group(:category).sum(:amount)
    else
      redirect_to landing_path
    end
  end

  def dashboard
    if user_signed_in?
      @transactions = current_user.transactions.order(transaction_date: :desc)
      @chart_data = current_user.transactions.group(:category).sum(:amount)
    else
      redirect_to new_user_session_path, alert: "Please sign in to view your dashboard."
    end
  end

  def landing
    redirect_to root_path if user_signed_in?
  end
end
