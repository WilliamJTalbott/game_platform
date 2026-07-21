require 'rails_helper'

class MessageableDummy
  include Messageable
  attr_accessor :messages

  def initialize
    @messages = []
  end
end

RSpec.describe Messageable do
  let(:dummy) { MessageableDummy.new }

  it "appends a normal message" do
    dummy.add_normal_message("hello")
    expect(dummy.messages).to contain_exactly(have_attributes(type: :normal, text: "hello"))
  end

  it "appends an action message" do
    dummy.add_action_message("did a thing")
    expect(dummy.messages).to contain_exactly(have_attributes(type: :action, text: "did a thing"))
  end

  it "appends an alert message" do
    dummy.add_alert_message("watch out")
    expect(dummy.messages).to contain_exactly(have_attributes(type: :alert, text: "watch out"))
  end
end
