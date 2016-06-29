class InviteMailer < ApplicationMailer
  default from: 'rcoback@gmail.com'

  def invite_email(user)
    @user = user
    @url = 'http://example.com/login'
    mail(to: 'whenthegroundcavedin@gmail.com', subject: 'RConnector Group Invitation')
  end
end
