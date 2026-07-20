module RequestAuthHelpers
  def sign_in(user, password: "password")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure { |config| config.include RequestAuthHelpers, type: :request }
