class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :temp_csv_data, class_name: "TempCsvData", dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :plaid_items, dependent: :destroy

  # validates :name, presence: true, allow_blank: true
end
