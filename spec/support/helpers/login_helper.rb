module LoginHelper
  
  def login_user(user)
    visit new_session_path
    fill_in :email_address, with: user.email_address
    fill_in :password, with: user.password
    click_button 'Log in'
  end

  def sign_up(email, password, confirm_password = password)
    visit new_user_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    fill_in "Confirm Password", with: confirm_password
    click_button 'Sign up'
  end

end