module LoginHelper
  
  def login_user(user)
    visit new_session_path
    fill_in :email_address, with: user.email_address
    fill_in :password, with: user.password
    click_button 'Log in'
  end

  def sign_up(email, password, confirm_password = password)
    visit new_user_path
    fill_in :email_address, with: email
    fill_in :password, with: password
    fill_in :password_confirmation, with: password
    click_button 'Sign up'
  end

end