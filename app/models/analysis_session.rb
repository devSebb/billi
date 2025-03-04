class AnalysisSession < ApplicationRecord
  belongs_to :user
  has_one_attached :csv_file
  has_many :transactions, dependent: :destroy
end
