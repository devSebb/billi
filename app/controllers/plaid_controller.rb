class PlaidController < ApplicationController
  before_action :authenticate_user! # Assuming Devise or similar for authentication

  def create_link_token
    link_token_request = Plaid::LinkTokenCreateRequest.new(
      user: { client_user_id: current_user.id.to_s },
      client_name: "Billi",
      products: [ "transactions" ], # Use 'auth' or others as needed
      country_codes: [ "US" ], # Add more as needed
      language: "en"
    )

    response = PlaidClient.link_token_create(link_token_request)
    render json: { link_token: response.link_token }
  rescue Plaid::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def exchange_public_token
    request = Plaid::ItemPublicTokenExchangeRequest.new(
      public_token: params[:public_token]
    )
    response = PlaidClient.item_public_token_exchange(request)

    # Create Plaid item and fetch initial transactions
    plaid_item = current_user.plaid_items.create!(
      access_token: response.access_token,
      item_id: response.item_id
    )

    sync_transactions(plaid_item)

    render json: { success: true }
  rescue Plaid::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def sync_transactions(plaid_item)
    request = Plaid::TransactionsGetRequest.new(
      access_token: plaid_item.access_token,
      start_date: Date.today - 30,
      end_date: Date.today
    )

    response = PlaidClient.transactions_get(request)

    response.transactions.each do |txn|
      plaid_item.transactions.create!(
        user: current_user,
        amount: txn.amount,
        transaction_date: txn.date,
        merchant: txn.merchant_name || "Unknown",
        category: txn.category&.join(", ") || "Other",
        currency: txn.iso_currency_code || "USD",
        country: "US" # Default for Plaid sandbox
      )
    end
  end
end
