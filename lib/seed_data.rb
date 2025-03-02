module SeedData
  def self.account_data
    {
      plaid_account_id: "BxBXxLj1m4HMXBm9WZZmCWVbPjX16EHwv99vp",
      balance: 110.94,
      currency: "USD",
      name: "Plaid Checking",
      official_name: "Plaid Gold Standard 0% Interest Checking",
      account_type: "depository",
      account_subtype: "checking"
    }
  end

  def self.transactions_data
    data = [
      {
        amount: 72.10,
        currency: "USD",
        category: "Shops",
        merchant: "Walmart",
        transaction_date: "2023-09-24",
        country: "US"
      },
      {
        amount: 28.34,
        currency: "USD",
        category: "Food and Drink",
        merchant: "Burger King",
        transaction_date: "2023-09-28",
        country: "US"
      },
      {
        amount: 156.50,
        currency: "EUR",
        category: "Shopping",
        sub_category: "Clothing",
        merchant: "Zara",
        transaction_date: "2023-09-29",
        country: "FR",
        city: "Paris",
        payment_channel: "in store",
        personal_finance_category: "SHOPPING",
        transaction_id: "kLMnOP3qR4sTuV5wXyZ7abCdEf8gHiJk"
      },
      {
        amount: 42.99,
        currency: "GBP",
        category: "Entertainment",
        sub_category: "Movies",
        merchant: "Odeon Cinema",
        transaction_date: "2023-09-30",
        country: "GB",
        city: "London",
        payment_channel: "online",
        personal_finance_category: "ENTERTAINMENT",
        transaction_id: "mNoPqR5sTuVwXyZ2aBcDeFgHiJkLmNo"
      },
      {
        amount: 89.90,
        currency: "USD",
        category: "Travel",
        sub_category: "Airlines",
        merchant: "British Airways",
        transaction_date: "2023-10-01",
        country: "GB",
        city: "London",
        payment_channel: "online",
        personal_finance_category: "TRAVEL",
        transaction_id: "pQrStU7vWxYzAb3cDeFgHiJkLmNoPqR"
      },
      {
        amount: 125.75,
        currency: "CAD",
        category: "Shopping",
        sub_category: "Electronics",
        merchant: "Best Buy",
        transaction_date: "2023-10-02",
        country: "CA",
        city: "Toronto",
        payment_channel: "in store",
        personal_finance_category: "SHOPPING",
        transaction_id: "sTuVwX9yZaBcDeF4gHiJkLmNoPqRsTu"
      },
      {
        amount: 33.50,
        currency: "AUD",
        category: "Food and Drink",
        sub_category: "Restaurants",
        merchant: "Melbourne Cafe",
        transaction_date: "2023-10-03",
        country: "AU",
        city: "Melbourne",
        payment_channel: "in store",
        personal_finance_category: "FOOD_AND_DRINK",
        transaction_id: "vWxYzA1bCdEfGh6iJkLmNoPqRsTuVwX"
      }
    ]
    data
  end
end
