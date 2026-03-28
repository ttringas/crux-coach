class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :public_page?

  helper_method :current_climber_profile

  protected

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def after_sign_up_path_for(_resource)
    onboarding_path(1)
  end

  def current_climber_profile
    return unless user_signed_in?

    current_user.climber_profile || current_user.create_climber_profile
  end

  def public_page?
    controller_name == "pages" && action_name == "home"
  end
end
