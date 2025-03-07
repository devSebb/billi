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

  private

  def log_creation
    Rails.logger.debug "Created transaction: #{attributes.inspect}"
  end
end
