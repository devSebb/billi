class HomeController < ApplicationController
  def index
    if user_signed_in?
      @transactions = current_user.transactions.order(transaction_date: :desc)
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
