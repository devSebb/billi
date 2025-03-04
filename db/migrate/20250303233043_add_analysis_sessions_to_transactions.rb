class AddAnalysisSessionsToTransactions < ActiveRecord::Migration[7.2]
  def change
    def change
      add_reference :transactions, :analysis_session, foreign_key: true
    end
  end
end
