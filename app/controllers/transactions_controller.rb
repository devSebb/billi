# app/controllers/transactions_controller.rb
require "csv"
require_relative "../../lib/seed_data"

class TransactionsController < ApplicationController
  include Pagy::Backend
  include TransactionFilterable
  before_action :authenticate_user!
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [ :chart_data ]

  # POST /transactions
  # Creates a new manual transaction
  def create
    @transaction = current_user.transactions.new(transaction_params)

    if @transaction.save
      redirect_to root_path, notice: "Transaction was successfully created."
    else
      redirect_to root_path, alert: "Error creating transaction: #{@transaction.errors.full_messages.join(', ')}"
    end
  end

  # GET /transactions/new
  def new
  end

  # POST /transactions/upload_csv
  def upload_csv
    if params[:file].present?
      begin
        unless params[:file].content_type == "text/csv"
          raise "Invalid file type. Please upload a CSV file."
        end

        # Create a new analysis session
        @analysis_session = current_user.analysis_sessions.new(
          name: params[:file].original_filename,
          status: "processing"
        )
        @analysis_session.csv_file.attach(params[:file])

        if @analysis_session.save
          csv_data = CSV.read(params[:file].tempfile, headers: true)
          mapping = auto_map_columns(csv_data.headers)

          transaction_count = 0
          errors = []

          csv_data.each_with_index do |row, index|
            begin
              row_hash = row.to_h

              raw_amount = row_hash[mapping[:amount]]
              Rails.logger.info "Row #{index + 1}: Raw amount: '#{raw_amount}'"


              date = clean_date(row_hash[mapping[:transaction_date]])
              original_category = clean_string(row_hash[mapping[:category]], default: "Other")
              merchant = clean_string(row_hash[mapping[:merchant]], default: "Unknown")

              # Handle amounts for Payment category and negative amounts
              amount = clean_amount(raw_amount)

              if amount.nil?
                Rails.logger.info "Skipping row #{index + 1}: Invalid amount format (raw value: '#{raw_amount}')"
                errors << "Row #{index + 1}: Invalid amount format (raw value: '#{raw_amount}')"
                next
              end

              Rails.logger.info "Row #{index + 1}: Cleaned amount: #{amount}"

              transaction = current_user.transactions.create!(
                amount: amount,
                currency: "USD",
                country: "US",
                category: original_category,
                merchant: merchant,
                transaction_date: date || Date.today
              )

              Rails.logger.info "Created transaction: amount=#{amount}, category=#{original_category}"
              transaction_count += 1
            rescue StandardError => e
              errors << "Row #{index + 1}: #{e.message}"
              Rails.logger.error "Error on row #{index + 1}: #{e.full_message}"
              next
            end
          end

          if transaction_count > 0
            @analysis_session.update(status: "completed")
            redirect_to root_path, notice: "Successfully processed #{transaction_count} transactions."
          else
            @analysis_session.update(status: "failed")
            raise "No transactions could be processed. Please check your CSV format."
          end
        else
          raise "Could not save analysis session"
        end
      rescue StandardError => e
        @analysis_session&.destroy
        redirect_to root_path, alert: "Error processing CSV: #{e.message}"
      end
    else
      redirect_to root_path, alert: "Please choose a CSV file."
    end
  end

  def clean_amount(amount_str)
    return nil if amount_str.blank?
    amount_str = amount_str.to_s.strip
    cleaned = amount_str.gsub(/[()]/, "").gsub(/[^0-9.-]/, "")
    amount = Float(cleaned) rescue nil
    return nil if amount.nil?
    amount
  end

  def process_mapped_csv
    if session[:temp_csv_id].present? && params[:mapping].present?
      begin
        temp_data = current_user.temp_csv_data.find(session[:temp_csv_id])

        current_user.transactions.destroy_all

        transaction_count = 0
        temp_data.data.each_with_index do |row, index|
          begin
            # Extract and clean values
            amount = clean_amount(row[params[:mapping][:amount]])
            date = clean_date(row[params[:mapping][:transaction_date]])

            # Skip invalid rows
            next if amount.nil?

            mapped_data = {
              amount: amount,
              currency: clean_string(row[params[:mapping][:currency]], default: "USD"),
              country: clean_string(row[params[:mapping][:country]], default: "Unknown"),
              category: clean_string(row[params[:mapping][:category]], default: "Other"),
              merchant: clean_string(row[params[:mapping][:merchant]], default: "Unknown"),
              transaction_date: date || Date.today # Use today's date if parsing fails
            }

            # Create the transaction
            current_user.transactions.create!(mapped_data)
            transaction_count += 1
          rescue StandardError => e
            next
          end
        end

        if transaction_count > 0
          temp_data.destroy
          session.delete(:temp_csv_id)
          redirect_to root_path, notice: "Successfully processed #{transaction_count} transactions."
        else
          raise "Could not process any rows. Please ensure the amount column contains numeric values."
        end
      rescue StandardError => e
        redirect_to root_path, alert: "Error processing data: #{e.message}"
      end
    else
      redirect_to root_path, alert: "No CSV data found or mapping not provided."
    end
  end

  # GET /transactions
  def index
    @transactions = Current.user.transactions.includes(:analysis_session, :plaid_item)
    filtered_transactions = filter_transactions(@transactions)
    sorted_transactions = sort_transactions(filtered_transactions)
    @pagy, @transactions = pagy(sorted_transactions)

    @time_series_data = {
      dates: [],
      spent: [],
      assets: []
    }

    # Get monthly data
    monthly_data = Current.user.transactions.group_by_month(:transaction_date).group(:category).sum(:amount)

    # Process the data
    dates = monthly_data.keys.map(&:first).uniq
    @time_series_data = {
      # Format dates as "Month Year" (e.g. "January 2024")
      dates: dates.map { |date| date.strftime("%B %Y") },

      # Calculate total spending per month (excluding Assets category)
      spent: dates.map do |date|
        monthly_spending = monthly_data.select do |key, _|
          month = key[0]
          category = key[1]
          month == date && category != "Salary"
        end
        monthly_spending.values.sum
      end,

      # Calculate total assets per month (absolute value)
      assets: dates.map do |date|
        monthly_assets = monthly_data.select do |key, _|
          month = key[0]
          category = key[1]
          month == date && category == "Salary"
        end
        monthly_assets.values.sum.abs
      end
    }
  end

  def reset
    if user_signed_in?
      current_user.transactions.destroy_all
      redirect_to root_path, notice: "All transactions have been cleared."
    else
      redirect_to root_path, alert: "You must be signed in to perform this action."
    end
  end

  def load_test_data
    if user_signed_in?
      begin
        # Clear existing transactions
        current_user.transactions.destroy_all

        # Get test data from SeedData module directly
        transactions_data = SeedData.transactions_data

        # Create transactions for current user
        transactions_created = 0
        transactions_data.each do |tx_data|
          transaction = current_user.transactions.create!(
            amount: tx_data[:amount],
            currency: tx_data[:currency],
            category: tx_data[:category],
            merchant: tx_data[:merchant],
            transaction_date: tx_data[:transaction_date],
            country: tx_data[:country]
          )
          transactions_created += 1
        end

        redirect_to root_path, notice: "Successfully loaded #{transactions_created} test transactions."
      rescue StandardError => e
        redirect_to root_path, alert: "Error loading test data: #{e.message}"
      end
    else
      redirect_to root_path, alert: "You must be signed in to perform this action."
    end
  end

  def chart_data
    group_by = params[:group_by] || "category"
    aggregate = params[:aggregate] || "sum"

    data = case aggregate
    when "sum"
      current_user.transactions.group(group_by).sum(:amount)
    when "count"
      current_user.transactions.group(group_by).count
    when "avg"
      current_user.transactions.group(group_by).average(:amount)
    end

    label = case aggregate
    when "sum"
      "Total Amount"
    when "count"
      "Number of Transactions"
    when "avg"
      "Average Amount"
    end

    render json: {
      labels: data.keys,
      values: data.values,
      label: "#{label} by #{group_by.titleize}"
    }
  end

  def destroy_analysis_session
    @analysis_session = current_user.analysis_sessions.find(params[:id])
    @analysis_session.destroy

    redirect_to user_profile_path, notice: "CSV file and associated data deleted successfully."
  rescue ActiveRecord::RecordNotFound
    redirect_to user_profile_path, alert: "CSV file not found."
  end

  def time_series_data
    # Group transactions by month and calculate totals
    monthly_data = Current.user.transactions.group_by_month(:transaction_date).group(:category).sum(:amount)

    # Process the data into the format needed for the chart
    dates = monthly_data.keys.map(&:first).uniq
    spent_by_month = dates.map do |date|
      monthly_data.select { |k, _| k[0] == date && k[1] != "Assets" }.values.sum
    end
    assets_by_month = dates.map do |date|
      monthly_data.select { |k, _| k[0] == date && k[1] == "Assets" }.values.sum.abs
    end

    render json: {
      dates: dates.map { |d| d.strftime("%B %Y") },
      spent: spent_by_month,
      assets: assets_by_month
    }
  end

  def edit
    @transaction = Transaction.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "edit-transaction-modal-1",
          partial: "shared/edit_transaction_modal",
          locals: { transaction: @transaction }
        )
      end
    end
  end

  def update
    @transaction = Current.user.transactions.find(params[:id])

    if @transaction.update(transaction_params)
      # Fetch the updated list of transactions (adjust query as needed)
      @transactions = Current.user.transactions.order(transaction_date: :desc)
      # Add pagination if you're using the Pagy gem
      @pagy, @transactions = pagy(@transactions) if defined?(pagy)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # Update the transactions-table Turbo Frame with the updated data
            turbo_stream.replace("transactions-table",
              partial: "shared/transactions_table",
              locals: { transactions: @transactions, pagy: @pagy }),
            turbo_stream.append("body", "<script>document.getElementById('edit-transaction-modal-1').close()</script>")
          ]
        end
      end
    else
      # If update fails, re-render the modal with errors
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("edit-transaction-modal",
            partial: "shared/edit_transaction_modal",
            locals: { transaction: @transaction })
        end
      end
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:amount, :currency, :country, :category, :merchant, :transaction_date)
  end

  def validate_csv_headers(headers)
    required_headers = [ "amount", "currency", "country", "category", "merchant", "transaction_date" ]
    missing_headers = required_headers - headers
    if missing_headers.any?
      raise "Missing required headers: #{missing_headers.join(', ')}"
    end
  end

  def clean_string(value, default: "")
    return default if value.blank?

    cleaned = value.to_s
                  .strip
                  .gsub(/[^\w\s-]/, "")
                  .gsub(/\s+/, " ")

    cleaned.presence || default
  end

  def clean_date(value)
    return Date.today if value.blank?

    begin
      # Parsing as a number
      if value.to_s.match?(/^\d+$/)
        base_date = Date.new(1899, 12, 30)
        return base_date + value.to_i
      end

      # Remove any surrounding quotes and clean the string
      cleaned = value.to_s
                    .gsub(/^["']|["']$/, "")
                    .strip
                    .gsub(/[^\w\s.\/-]/, "")

      # Try various date formats
      date_formats = [
        "%Y-%m-%d",
        "%m/%d/%Y",
        "%d/%m/%Y",
        "%d-%m-%Y",
        "%Y/%m/%d",
        "%d.%m.%Y",
        "%Y.%m.%d",
        "%b %d %Y",
        "%B %d %Y",
        "%d %b %Y",
        "%d %B %Y",
        "%Y-%m-%d %H:%M:%S",
        "%m/%d/%y",
        "%d/%m/%y",
        "%y-%m-%d"
      ]

      date_formats.each do |format|
        begin
          return Date.strptime(cleaned, format)
        rescue Date::Error
          next
        end
      end

      # If none of the formats work, let Ruby try to parse it
      Date.parse(cleaned)
    rescue StandardError => e
      Date.today
    end
  end

  def auto_map_columns(headers)
    original_headers = headers
    headers_downcase = headers.map { |h| h.to_s.downcase.strip }

    mapping = {}
    # Map amount column: any header that includes "amount"
    if headers_downcase.any? { |h| h.include?("amount") }
      mapping[:amount] = original_headers[headers_downcase.index { |h| h.include?("amount") }]
    end

    if headers_downcase.any? { |h| h.include?("date") }
      mapping[:transaction_date] = original_headers[headers_downcase.index { |h| h.include?("date") }]
    end

    if headers_downcase.any? { |h| h.include?("category") }
      mapping[:category] = original_headers[headers_downcase.index { |h| h.include?("category") }]
    end

    if headers_downcase.any? { |h| h.include?("merchant") }
      mapping[:merchant] = original_headers[headers_downcase.index { |h| h.include?("merchant") }]
    end

    if headers_downcase.any? { |h| h.include?("currency") }
      mapping[:currency] = original_headers[headers_downcase.index { |h| h.include?("currency") }]
    end

    if headers_downcase.any? { |h| h.include?("country") }
      mapping[:country] = original_headers[headers_downcase.index { |h| h.include?("country") }]
    end

    unless mapping[:amount] && mapping[:transaction_date]
      Rails.logger.error "Missing required fields. Headers available: #{original_headers.join(', ')}"
      raise "Could not find required fields in CSV. Need an 'amount' column and a 'transaction date' column."
    end

    mapping
  end

  def prepare_time_series_data
    monthly_data = Current.user.transactions.group_by_month(:transaction_date).group(:category).sum(:amount)
    dates = monthly_data.keys.map(&:first).uniq

    {
      dates: dates.map { |d| d.strftime("%B %Y") },
      spent: dates.map do |date|
        monthly_data.select { |k, _| k[0] == date && k[1] != "Assets" }.values.sum
      end,
      assets: dates.map do |date|
        monthly_data.select { |k, _| k[0] == date && k[1] == "Assets" }.values.sum.abs
      end
    }
  end
end
