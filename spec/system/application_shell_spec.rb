require 'rails_helper'

RSpec.describe "Application shell", type: :system do
  let(:user) { create(:user) }

  before { login_user(user) }

  # `.op-page` is a grid and `.sidebar` is one of its items, so ANY element added
  # as a sibling in the layout claims a grid cell and displaces it — an empty
  # wrapper around the flash slot was enough to push the sidebar into the second
  # column on every page in the app. Nothing else in the suite looks at where the
  # shell's columns land, so this is the guard.
  context "when the layout renders the flash slot alongside the sidebar" do
    it "keeps the sidebar in the first column", :js do
      visit root_path

      left = page.evaluate_script("document.querySelector('.sidebar').getBoundingClientRect().left")
      expect(left).to eq 0
    end
  end
end
