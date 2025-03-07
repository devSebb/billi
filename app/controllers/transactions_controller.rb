# app/controllers/transactions_controller.rb
require "csv"
require_relative "../../lib/seed_data"

class TransactionsController < ApplicationController
  include Pagy::Backend
  include TransactionFilterable
  before_action :authenticate_user!
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [ :chart_data ]

  # GET /transactions/new
  # Renders the CSV upload form
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

              # Get other fields
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
    return nil if amount_str.nil? || amount_str.strip.empty?  # Handle nil or empty strings

    amount_str = amount_str.to_s.strip  # Remove leading/trailing spaces

    # Handle parentheses for negative amounts (e.g., "(100.00)" -> "-100.00")
    if amount_str.start_with?("(") && amount_str.end_with?(")")
      amount_str = "-" + amount_str[1..-2]
    end

    # Remove non-numeric characters except digits, decimal point, and minus sign
    cleaned = amount_str.gsub(/[^0-9.-]/, "")

    # Handle trailing minus sign (e.g., "100.00-" -> "-100.00")
    if cleaned.end_with?("-")
      cleaned = "-" + cleaned.chop
    end

    # Convert to float, return nil if parsing fails
    begin
      Float(cleaned)
    rescue ArgumentError, TypeError
      nil
    end
  end

  def process_mapped_csv
    if session[:temp_csv_id].present? && params[:mapping].present?
      begin
        temp_data = current_user.temp_csv_data.find(session[:temp_csv_id])

        # Clear existing transactions
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
  # Displays the analysis of transactions in a table and via Chart.js
  def index
    @transactions = Current.user.transactions.includes(:analysis_session, :plaid_item)
    base_transactions = current_user.transactions
    sorted_transactions = sort_transactions(base_transactions)
    @pagy, @transactions = pagy(sorted_transactions)
    @chart_data = base_transactions.group(:category).sum(:amount)
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

  # Add new action to delete analysis sessions
  def destroy_analysis_session
    @analysis_session = current_user.analysis_sessions.find(params[:id])
    @analysis_session.destroy

    redirect_to user_profile_path, notice: "CSV file and associated data deleted successfully."
  rescue ActiveRecord::RecordNotFound
    redirect_to user_profile_path, alert: "CSV file not found."
  end

  private

  def validate_csv_headers(headers)
    required_headers = [ "amount", "currency", "country", "category", "merchant", "transaction_date" ]
    missing_headers = required_headers - headers
    if missing_headers.any?
      raise "Missing required headers: #{missing_headers.join(', ')}"
    end
  end

  # def clean_amount(value)
  #   return nil if value.blank?

  #   amount_str = value.to_s.strip
  #   Rails.logger.info "Processing amount: '#{amount_str}'"

  #   cleaned_str = amount_str.gsub(/[^-\d.]/, "").gsub(/(-)+/, "-").strip

  #   begin
  #     amount = Float(cleaned_str)
  #     Rails.logger.info "Processed amount: #{amount}"
  #     amount
  #   rescue ArgumentError => e
  #     Rails.logger.error "Failed to parse amount '#{amount_str}': #{e.message}"
  #     nil
  #   end
  # end

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
                    .gsub(/[^\w\s.\/-]/, "")

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

    # Map transaction_date column: any header that includes "date"
    if headers_downcase.any? { |h| h.include?("date") }
      mapping[:transaction_date] = original_headers[headers_downcase.index { |h| h.include?("date") }]
    end

    # Optional mappings – if available in CSV
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
end
