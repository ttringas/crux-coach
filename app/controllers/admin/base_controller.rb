# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      redirect_to calendar_path, alert: "You do not have access to that page."
    end
  end
end
