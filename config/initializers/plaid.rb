require "plaid"

PlaidClient = Plaid::PlaidApi.new(
  Plaid::ApiClient.new(
    Plaid::Configuration.new.tap do |config|
      # Use sandbox for testing with test data
      config.server_index = Plaid::Configuration::Environment["sandbox"]
      config.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_CLIENT_ID"]
      config.api_key["PLAID-SECRET"] = ENV["PLAID_SECRET"]
      config.api_key["Plaid-Version"] = "2020-09-14" # Latest stable version as per docs
    end
  )
)
