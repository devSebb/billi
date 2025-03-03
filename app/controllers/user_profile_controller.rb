class UserProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @plaid_items = @user.plaid_items
  end
end
