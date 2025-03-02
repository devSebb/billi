class HomeController < ApplicationController
  def index
    if user_signed_in?
      # Get transactions for the table display
      @transactions = current_user.transactions.order(transaction_date: :desc)
      Rails.logger.debug "Found #{@transactions.count} transactions for user #{current_user.id}"

      if @transactions.present?
        # Get chart data separately without the order clause
        @chart_data = current_user.transactions
                                 .group(:country)
                                 .sum(:amount)
                                 .transform_values { |v| v.round(2) }
        Rails.logger.debug "Chart data: #{@chart_data.inspect}"
      end
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
end
