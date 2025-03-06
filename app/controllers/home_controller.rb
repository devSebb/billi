class HomeController < ApplicationController
  include TransactionFilterable
  include Pagy::Backend

  def index
    if user_signed_in?
      # Remove the includes for analysis_session since the association doesn't exist
      base_transactions = Current.user.transactions

      # Calculate stats from all transactions
      @total_transactions = base_transactions.count
      @total_spent = base_transactions.where("amount > 0").sum(:amount) # Only sum positive amounts
      @average_transaction = base_transactions.where("amount > 0").average(:amount)
      @upload_count = Current.user.analysis_sessions.count + Current.user.plaid_items.count

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
