require 'rails_helper'

RSpec.describe User, type: :model do

  context "When valid email is passed in" do
    let(:user) { build(:user, email_address: "toast@jelly.com") }
    it "is valid" do
      expect(user).to be_valid
    end
  end

  context "When invalid email is passed in" do
    let(:user) { build(:user, email_address: "toast") }
    it "is invalid" do
      expect(user).to be_invalid
    end
  end

  context "When valid password is passed in" do
    let(:user) { build(:user, password: "The0End#Is!Nigh") }
    it "is valid" do
      expect(user).to be_valid
    end
  end

  context "When invalid password is passed in" do
    let(:user) { build(:user, password: "toast") }
    it "is invalid" do
      expect(user).to be_invalid
    end
  end

end
