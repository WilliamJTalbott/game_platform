module LoginHelper
  
  def login_user(user)
    visit new_session_path
    fill_in :email_address, with: user.email_address
    fill_in :password, with: user.password
    click_button 'Sign in'
  end

end