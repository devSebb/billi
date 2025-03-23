class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :plaid_item, optional: true
  belongs_to :analysis_session, optional: true

  validates :amount, presence: true, numericality: true
  validates :currency, presence: true
  validates :category, presence: true
  validates :merchant, presence: true
  validates :transaction_date, presence: true
  validates :country, presence: true

  after_create :log_creation

  include PgSearch::Model
  pg_search_scope :search, against: {
    merchant: "A",
    category: "B",
    country: "C"
  }, using: {
    tsearch: {
      prefix: true,
      dictionary: "simple"
    }
  }

  scope :search_with_aggregates, ->(query) {
    if query.present?
      base = search(query)
      base.select("transactions.*, pg_search_rank() as search_rank")
    else
      all
    end
  }

  private

  def log_creation
    Rails.logger.debug "Created transaction: #{attributes.inspect}"
  end
end
