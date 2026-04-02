class MagicLinkMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @code = user.magic_link_code
    @url = magic_link_url(token: token)

    mail(
      to: user.email,
      from: "hi@brooklynuprising.com",
      subject: "Your BKUP TRAIN login code: #{@code}"
    )
  end
end
