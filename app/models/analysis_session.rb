class AnalysisSession < ApplicationRecord
  belongs_to :user
  has_one_attached :csv_file
  has_many :transactions, -> { where(user_id: user_id) }, through: :user

  validates :name, presence: true
  validates :csv_file, presence: true

  # Add status enum for tracking processing state
  enum status: {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  def filename
    csv_file.filename.to_s if csv_file.attached?
  end
end
