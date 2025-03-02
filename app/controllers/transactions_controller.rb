# app/controllers/transactions_controller.rb
require "csv"
require_relative "../../lib/seed_data"

class TransactionsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [ :chart_data ]
  before_action :verify_authenticity_token, except: [ :chart_data ]

  # GET /transactions/new
  # Renders the CSV upload form
  def new
  end

  # POST /transactions/upload_csv
  def upload_csv
    if params[:file].present?
      begin
        Rails.logger.info "Starting CSV processing..."

        # Verify file is a CSV
        unless params[:file].content_type == "text/csv"
          raise "Invalid file type. Please upload a CSV file."
        end

        # Clear existing transactions
        current_user.transactions.destroy_all

        # Read CSV data
        csv_data = CSV.read(params[:file].tempfile, headers: true)

        # Auto-map columns based on closest match
        mapping = auto_map_columns(csv_data.headers)

        transaction_count = 0
        csv_data.each_with_index do |row, index|
          begin
            # Extract and clean values using the auto-mapped columns
            amount = clean_amount(row[mapping[:amount]])
            date = clean_date(row[mapping[:transaction_date]])

            next if amount.nil?

            transaction = current_user.transactions.create!(
              amount: amount,
              currency: clean_string(row[mapping[:currency]], default: "USD"),
              country: clean_string(row[mapping[:country]], default: "Unknown"),
              category: clean_string(row[mapping[:category]], default: "Other"),
              merchant: clean_string(row[mapping[:merchant]], default: "Unknown"),
              transaction_date: date || Date.today
            )
            transaction_count += 1
            Rails.logger.debug "Created transaction #{transaction_count}: #{transaction.attributes}"
          rescue StandardError => e
            Rails.logger.error "Error processing row #{index + 1}: #{e.message}"
            next
          end
        end

        if transaction_count > 0
          redirect_to root_path, notice: "Successfully processed #{transaction_count} transactions."
        else
          raise "Could not process any rows. Please check your CSV format."
        end
      rescue StandardError => e
        Rails.logger.error "CSV Processing Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to root_path, alert: "Error processing CSV: #{e.message}"
      end
    else
      Rails.logger.warn "No file uploaded"
      redirect_to root_path, alert: "Please choose a CSV file."
    end
  end

  def process_mapped_csv
    if session[:temp_csv_id].present? && params[:mapping].present?
      begin
        Rails.logger.info "Starting CSV processing with mapping: #{params[:mapping]}"
        temp_data = current_user.temp_csv_data.find(session[:temp_csv_id])
        Rails.logger.info "Found temp data with #{temp_data.data.size} rows"

        # Clear existing transactions
        current_user.transactions.destroy_all

        transaction_count = 0
        temp_data.data.each_with_index do |row, index|
          begin
            # Log the raw row data
            Rails.logger.info "Processing row #{index + 1}: #{row.inspect}"

            # Extract and clean values
            amount = clean_amount(row[params[:mapping][:amount]])
            date = clean_date(row[params[:mapping][:transaction_date]])

            Rails.logger.info "Cleaned amount: #{amount.inspect}, date: #{date.inspect}"

            # Skip invalid rows
            if amount.nil?
              Rails.logger.info "Skipping row #{index + 1} - invalid amount"
              next
            end

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
            Rails.logger.info "Successfully created transaction #{transaction_count}: #{mapped_data.inspect}"
          rescue StandardError => e
            Rails.logger.error "Error processing row #{index + 1}: #{e.message}"
            Rails.logger.error "Row data: #{row.inspect}"
            next
          end
        end

        if transaction_count > 0
          temp_data.destroy
          session.delete(:temp_csv_id)
          redirect_to root_path, notice: "Successfully processed #{transaction_count} transactions."
        else
          Rails.logger.error "Failed to process any rows. Sample data: #{temp_data.data.first.inspect}"
          raise "Could not process any rows. Please ensure the amount column contains numeric values."
        end
      rescue StandardError => e
        Rails.logger.error "Processing Error: #{e.message}"
        redirect_to root_path, alert: "Error processing data: #{e.message}"
      end
    else
      redirect_to root_path, alert: "No CSV data found or mapping not provided."
    end
  end

  # GET /transactions
  # Displays the analysis of transactions in a table and via Chart.js
  def index
    @transactions = current_user.transactions.order(transaction_date: :desc)
    # Prepare data for Chart.js
    # For example, aggregate total spending per country:
    @chart_data = current_user.transactions.group(:category).sum(:amount)
  end

  # Add this new action to the TransactionsController
  def reset
    if user_signed_in?
      current_user.transactions.destroy_all
      redirect_to root_path, notice: "All transactions have been cleared."
    else
      redirect_to root_path, alert: "You must be signed in to perform this action."
    end
  end

  # Add this new action to the TransactionsController
  def load_test_data
    if user_signed_in?
      begin
        Rails.logger.info "Loading test data for user #{current_user.email}..."

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
          Rails.logger.debug "Created transaction #{transactions_created}: #{transaction.attributes}"
        end

        Rails.logger.info "Successfully created #{transactions_created} test transactions"
        redirect_to root_path, notice: "Successfully loaded #{transactions_created} test transactions."
      rescue StandardError => e
        Rails.logger.error "Error loading test data: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
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

  private

  def validate_csv_headers(headers)
    required_headers = [ "amount", "currency", "country", "category", "merchant", "transaction_date" ]
    missing_headers = required_headers - headers
    if missing_headers.any?
      Rails.logger.error "Missing headers: #{missing_headers.join(', ')}"
      raise "Missing required headers: #{missing_headers.join(', ')}"
    end
  end

  def clean_amount(value)
    return nil if value.blank?

    # Convert to string and clean up
    amount_str = value.to_s.strip

    # Remove any currency symbols and common prefixes
    amount_str = amount_str.gsub(/[£$€¥]|USD|EUR|GBP|JPY/i, "")

    # Remove any parentheses and their contents
    amount_str = amount_str.gsub(/\(.*?\)/, "")

    # Replace various separators and remove spaces
    amount_str = amount_str.gsub(/[,\s]/, "")

    # Handle negative amounts marked with parentheses or minus sign
    is_negative = amount_str.include?("(") || amount_str.include?("-")
    amount_str = amount_str.gsub(/[-()]/, "")

    # Convert to float
    amount = amount_str.to_f
    amount = -amount if is_negative

    # Return the absolute value (we want positive numbers)
    amount.abs
  rescue StandardError => e
    Rails.logger.warn "Error cleaning amount '#{value}': #{e.message}"
    nil
  end

  def clean_string(value, default: "")
    return default if value.blank?

    # Remove special characters and extra spaces
    cleaned = value.to_s
                  .strip
                  .gsub(/[^\w\s-]/, "") # Remove special characters except hyphen
                  .gsub(/\s+/, " ")     # Replace multiple spaces with single space

    cleaned.presence || default
  end

  def clean_date(value)
    return Date.today if value.blank?

    # Try to parse the date string
    begin
      # First try parsing as a number (Excel date)
      if value.to_s.match?(/^\d+$/)
        base_date = Date.new(1899, 12, 30)
        return base_date + value.to_i
      end

      # Remove any surrounding quotes and clean the string
      cleaned = value.to_s
                    .gsub(/^["']|["']$/, "")
                    .strip
                    .gsub(/[^\w\s.\/-]/, "") # Fixed regex: moved hyphen to end of character class

      # Try various date formats
      date_formats = [
        "%Y-%m-%d",
        "%d/%m/%Y",
        "%m/%d/%Y",
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

      # If none of the formats work, try letting Ruby parse it
      Date.parse(cleaned)
    rescue StandardError => e
      Rails.logger.warn "Could not parse date '#{value}': #{e.message}"
      Date.today  # Always return a valid date
    end
  end

  def auto_map_columns(headers)
    headers = headers.map { |h| h.to_s.downcase.strip }

    mapping = {}

    # Define possible matches for each required field
    field_matches = {
      amount: [ "amount", "sum", "total", "price", "cost", "value" ],
      currency: [ "currency", "cur", "ccy" ],
      country: [ "country", "region", "location", "geo" ],
      category: [ "category", "type", "transaction type", "trans type", "description" ],
      merchant: [ "merchant", "vendor", "store", "shop", "payee", "description" ],
      transaction_date: [ "date", "transaction date", "trans date", "payment date" ]
    }

    # Find best match for each field
    field_matches.each do |field, possible_matches|
      match = possible_matches.find { |m| headers.include?(m) }
      mapping[field] = match || headers.find { |h| h.include?(possible_matches[0]) } || headers.first
    end

    Rails.logger.debug "Auto-mapped columns: #{mapping.inspect}"
    mapping
  end
end
