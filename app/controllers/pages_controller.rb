class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    redirect_to authenticated_root_path if user_signed_in?
  end

  def authenticated_root
    redirect_to authenticated_root_path_for(current_user.climber_profile)
  end
end
