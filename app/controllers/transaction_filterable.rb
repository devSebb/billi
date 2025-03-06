module TransactionFilterable
  extend ActiveSupport::Concern

  def filter_transactions(transactions)
    # Apply date range filter
    if params[:start_date].present?
      transactions = transactions.where("transaction_date >= ?", params[:start_date])
    end

    if params[:end_date].present?
      transactions = transactions.where("transaction_date <= ?", params[:end_date])
    end

    # Apply category filter
    if params[:category].present?
      transactions = transactions.where(category: params[:category])
    end

    # Apply country filter
    if params[:country].present?
      transactions = transactions.where(country: params[:country])
    end

    transactions
  end

  def sort_transactions(transactions)
    sort_column = params[:sort].presence || "transaction_date"
    direction = sort_column == "transaction_date" ? "desc" : "asc"

    transactions.order(sort_column => direction)
  end
end
