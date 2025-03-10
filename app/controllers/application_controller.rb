class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  # before_action :authenticate_user!
  before_action :set_current_user
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_filter_options, if: :user_signed_in?

  private

  def set_current_user
    Current.user = current_user
  end

  def set_filter_options
    if @transactions.present?
      @categories = current_user.transactions.distinct.pluck(:category)
      @countries = current_user.transactions.distinct.pluck(:country)
    else
      @categories = []
      @countries = []
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end
end
