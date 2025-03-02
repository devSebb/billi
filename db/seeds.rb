require_relative '../lib/seed_data'

def seed_test_data(user)
  # Clear existing data for this user
  user.transactions.destroy_all

  # Get data from shared module
  transactions_data = SeedData.transactions_data

  puts "Creating transactions for user..."
  transactions_data.each do |tx_data|
    transaction = user.transactions.create!(
      amount: tx_data[:amount],
      currency: tx_data[:currency],
      category: tx_data[:category],
      merchant: tx_data[:merchant],
      transaction_date: tx_data[:transaction_date],
      country: tx_data[:country] || "Unknown"
    )
    puts "Created transaction: #{transaction.merchant} - #{transaction.amount}"
  end

  puts "Seed completed! Created #{transactions_data.length} transactions for #{user.email}"
end

# If running seeds directly (rails db:seed)
if caller.none? { |line| line.include?('load_test_data') }
  # Clear existing data
  puts "Clearing existing data..."
  User.find_each do |user|
    user.transactions.destroy_all
  end

  # Create test user if it doesn't exist
  test_user = User.find_or_create_by!(email: 'test@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
  end

  seed_test_data(test_user)
# If called from load_test_data action
else
  seed_test_data(Current.user || User.current)
end
