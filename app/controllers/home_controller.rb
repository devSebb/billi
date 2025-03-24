class HomeController < ApplicationController
  include TransactionFilterable
  include Pagy::Backend

  def index
    if user_signed_in?
      base_transactions = Current.user.transactions

      # Apply search if query present
      base_transactions = if params[:query].present?
        base_transactions.search(params[:query])
      else
        base_transactions
      end

      @analysis_sessions = Current.user.analysis_sessions.order(created_at: :desc)

      # Calculate stats from filtered transactions
      @total_transactions = base_transactions.count
      @total_spent = if params[:query].present?
        base_transactions.where("amount > 0").reorder("").sum(:amount)
      else
        base_transactions.where("amount > 0").sum(:amount)
      end
      @average_transaction = if params[:query].present?
        base_transactions.where("amount > 0").reorder("").average(:amount)
      else
        base_transactions.where("amount > 0").average(:amount)
      end
      @upload_count = Current.user.analysis_sessions.count + Current.user.plaid_items.count
      @payments = if params[:query].present?
        base_transactions.where("amount < 0").where(category: "Payment").reorder("").sum(:amount).abs
      else
        base_transactions.where("amount < 0").where(category: "Payment").sum(:amount).abs
      end
      @credit_transactions = if params[:query].present?
        base_transactions.where(category: "Credit").reorder("").sum(:amount)
      else
        base_transactions.where(category: "Credit").sum(:amount)
      end
      @income_transactions = if params[:query].present?
        -base_transactions.where("amount < 0").where.not(category: [ "Payment", "Credit" ]).reorder("").sum(:amount)
      else
        -base_transactions.where("amount < 0").where.not(category: [ "Payment", "Credit" ]).sum(:amount)
      end
      @expense_transactions = if params[:query].present?
        base_transactions.where("amount > 0").reorder("").sum(:amount)
      else
        base_transactions.where("amount > 0").sum(:amount)
      end
      @net_worth = (@income_transactions - @expense_transactions - @credit_transactions)
      @top_category = if params[:query].present?
        base_transactions
          .where("amount > 0")
          .reorder("")
          .group(:category)
          .sum(:amount)
          .max_by { |_, amount| amount }
          &.first
      else
        base_transactions
          .where("amount > 0")
          .group(:category)
          .sum(:amount)
          .max_by { |_, amount| amount }
          &.first
      end
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

      # Handle Turbo Frame requests
      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transactions-table",
            partial: "shared/transactions_table"
          )
        end
      end

      # For charts
      @chart_data = if params[:query].present?
        base_transactions.reorder("").group(:category).sum(:amount)
      else
        base_transactions.group(:category).sum(:amount)
      end

      # Add this for the chart
      @time_series_data = prepare_time_series_data(base_transactions)

      # Additional calculations for modals
      @foreign_transactions = base_transactions
        .where("amount > 0")
        .where.not(country: nil)
        .sum(:amount)

      @recent_deposits = base_transactions
        .where("amount < 0")
        .where("transaction_date >= ?", 30.days.ago)
        .sum(:amount)
        .abs

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

  private

  def prepare_time_series_data(transactions = nil)
    transactions ||= Current.user.transactions
    weekly_data = if params[:query].present?
      transactions.reorder("").group_by_week(:transaction_date).group(:category).sum(:amount)
    else
      transactions.group_by_week(:transaction_date).group(:category).sum(:amount)
    end

    dates = weekly_data.keys.map(&:first).uniq

    {
      dates: dates.map { |d| d.strftime("%Y-%m-%d") },
      spent: dates.map { |date|
        weekly_data.select { |k, _|
          k[0] == date &&
          weekly_data[[ k[0], k[1] ]] > 0
        }.values.sum
      },
      assets: dates.map { |date|
        weekly_data.select { |k, _| k[0] == date && k[1] == "Assets" }.values.sum.abs
      },
      income: dates.map { |date|
        weekly_data.select { |k, _|
          k[0] == date &&
          weekly_data[[ k[0], k[1] ]] < 0
        }.values.sum.abs
      }
    }
  end
end
