class UserProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @plaid_items = @user.plaid_items
    @analysis_sessions = @user.analysis_sessions.order(created_at: :desc)
  end
end
