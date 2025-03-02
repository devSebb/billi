class TempCsvData < ApplicationRecord
  self.table_name = "temp_csv_data"  # Explicitly set the table name

  belongs_to :user

  # Automatically cleanup old temporary data
  scope :old, -> { where("created_at < ?", 1.hour.ago) }

  def self.cleanup_old_data
    old.destroy_all
  end
end
