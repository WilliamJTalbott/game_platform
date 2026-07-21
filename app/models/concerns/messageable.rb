module Messageable
  def add_normal_message(text)
    messages << CardGame::Message.new(:normal, text)
  end

  def add_action_message(text)
    messages << CardGame::Message.new(:action, text)
  end

  def add_alert_message(text)
    messages << CardGame::Message.new(:alert, text)
  end
end
