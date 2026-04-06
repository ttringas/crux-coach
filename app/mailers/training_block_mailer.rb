class TrainingBlockMailer < ApplicationMailer
  def generation_complete(user, training_block)
    @user = user
    @training_block = training_block
    @url = training_blocks_url(anchor: training_block.id)

    mail(
      to: user.email,
      from: "hi@brooklynuprising.com",
      subject: "Your training plan is ready!"
    )
  end
end
