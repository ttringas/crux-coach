class MagicSessionsController < ApplicationController
  def new
    render "devise/sessions/new"
  end

  def create
    email = Array(params[:email]).first.to_s.strip.downcase
    if email.blank?
      redirect_to new_user_session_path, alert: "Please enter a valid email address."
      return
    end

    user = User.find_or_initialize_by(email: email)
    unless user.save
      redirect_to new_user_session_path, alert: "Please enter a valid email address."
      return
    end

    token = SecureRandom.urlsafe_base64(32)
    code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")

    user.update!(magic_link_token: token, magic_link_code: code, magic_link_sent_at: Time.current)
    MagicLinkMailer.magic_link(user, token).deliver_now

    redirect_to new_user_session_path(sent: 1, email: user.email)
  end

  def verify_code
    email = Array(params[:email]).first.to_s.strip.downcase
    code = Array(params[:code]).first.to_s.strip
    user = User.find_by("LOWER(email) = LOWER(?)", email)

    if user && user.magic_link_code == code && user.magic_link_sent_at&.>(30.minutes.ago)
      sign_in(user)
      user.update!(magic_link_token: nil, magic_link_code: nil, magic_link_sent_at: nil)
      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path(sent: 1, email: params[:email]), alert: "Invalid or expired code. Please try again or request a new link."
    end
  end

  def magic_link
    user = User.find_by(magic_link_token: params[:token])

    if user && user.magic_link_sent_at&.>(30.minutes.ago)
      sign_in(user)
      user.update!(magic_link_token: nil, magic_link_code: nil, magic_link_sent_at: nil)
      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path, alert: "Invalid or expired link. Please request a new one."
    end
  end

  def destroy
    sign_out(:user)
    redirect_to root_path, notice: "Signed out."
  end
end
