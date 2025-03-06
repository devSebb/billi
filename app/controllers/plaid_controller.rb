class PlaidController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session, only: [ :exchange_public_token ]

  def create_link_token
    link_token_request = Plaid::LinkTokenCreateRequest.new(
      user: { client_user_id: current_user.id.to_s },
      client_name: "Billi",
      products: [ "transactions" ],
      country_codes: [ "US" ],
      language: "en"
    )

    response = PlaidClient.link_token_create(link_token_request)
    render json: { link_token: response.link_token }
  rescue Plaid::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def exchange_public_token
    public_token = if request.content_type == "application/json"
                    JSON.parse(request.body.read)["public_token"]
    else
                    params[:public_token]
    end

    raise ArgumentError, "Missing public_token" if public_token.blank?

    request = Plaid::ItemPublicTokenExchangeRequest.new(
      public_token: public_token
    )

    response = PlaidClient.item_public_token_exchange(request)

    # Create Plaid item and fetch initial transactions
    plaid_item = current_user.plaid_items.create!(
      access_token: response.access_token,
      item_id: response.item_id
    )

    sync_transactions(plaid_item)

    render json: { success: true }
  rescue JSON::ParserError
    render json: { error: "Invalid JSON format" }, status: :bad_request
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  rescue Plaid::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Plaid exchange error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "An unexpected error occurred" }, status: :internal_server_error
  end

  # Modified to follow proper sandbox flow
  def create_sandbox_public_token
    # Step 1: Create a link token first
    link_token_request = Plaid::LinkTokenCreateRequest.new(
      user: { client_user_id: current_user.id.to_s },
      client_name: "Billi",
      products: [ "transactions" ],
      country_codes: [ "US" ],
      language: "en"
    )
    link_token_response = PlaidClient.link_token_create(link_token_request)

    # Step 2: Create sandbox public token
    sandbox_request = Plaid::SandboxPublicTokenCreateRequest.new(
      institution_id: "ins_109508",  # Sandbox test institution
      initial_products: [ "transactions" ]
    )
    sandbox_response = PlaidClient.sandbox_public_token_create(sandbox_request)

    render json: {
      link_token: link_token_response.link_token,
      public_token: sandbox_response.public_token
    }
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
        country: "US"
      )
    end
  end
end
