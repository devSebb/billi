module TransactionFilterable
  extend ActiveSupport::Concern

  def filter_transactions(transactions)
    transactions = apply_search(transactions)
    transactions = apply_date_filters(transactions)
    transactions = apply_category_filter(transactions)
    transactions = apply_country_filter(transactions)
    transactions
  end

  private

  def apply_search(transactions)
    return transactions unless params[:query].present?

    search_term = "%#{params[:query].downcase}%"
    transactions.where(
      "LOWER(merchant) LIKE :term OR
       LOWER(category) LIKE :term OR
       LOWER(country) LIKE :term OR
       LOWER(currency) LIKE :term OR
       CAST(amount AS TEXT) LIKE :term",
      term: search_term
    )
  end

  def sort_transactions(transactions)
    column = params[:sort].presence || "transaction_date"
    direction = params[:direction].presence || (column == "transaction_date" ? "desc" : "asc")

    transactions.order(column => direction)
  end

  def apply_date_filters(transactions)
    # Apply date range filter
    if params[:start_date].present?
      transactions = transactions.where("transaction_date >= ?", params[:start_date])
    end

    if params[:end_date].present?
      transactions = transactions.where("transaction_date <= ?", params[:end_date])
    end

    transactions
  end

  def apply_category_filter(transactions)
    # Apply category filter
    if params[:category].present?
      transactions = transactions.where(category: params[:category])
    end

    transactions
  end

  def apply_country_filter(transactions)
    # Apply country filter
    if params[:country].present?
      transactions = transactions.where(country: params[:country])
    end

    transactions
  end
end
