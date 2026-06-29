require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /rules" do
    it "returns http success" do
      get "/pages/rules"
      expect(response).to have_http_status(:success)
    end
  end

end
