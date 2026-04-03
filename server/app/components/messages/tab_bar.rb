# frozen_string_literal: true

class Components::Messages::TabBar < Components::Base
  prop :user, User
  prop :active, OneOf(:inbox, :conversations, :archive), default: :inbox

  def view_template
    StatusBar do |tabs|
      tabs.item state: state_for(:inbox), href: messages_path, label: Conversation::Message.an(:inbox)
      tabs.item state: state_for(:conversations), href: conversations_path, label: Conversation.pn
      tabs.item state: state_for(:archive), href: conversations_path(archive: true), label: Conversation.an(:archive)
    end
  end

  private def state_for tab
    (tab == @active) ? :online : :offline
  end
end
