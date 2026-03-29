# frozen_string_literal: true

class ListConversationsTool < SyntheticTool
  description "List your active conversations and pending requests."

  param :status, type: "string", desc: "Filter by status: active, requested, or all (default: all)", required: false

  def execute(status: "all")
    scope = Conversation.involving(@synthetic)
    scope = scope.where(status: status) unless status == "all"
    conversations = scope.order(updated_at: :desc).limit(20)

    return "No conversations found." if conversations.empty?

    conversations.map do |c|
      other = c.other_participant(@synthetic)
      unread = c.has_unread_messages_for?(@synthetic) ? " [UNREAD]" : ""
      "- [#{c.id}] #{c.subject} with #{other.name} (#{c.status})#{unread}"
    end.join("\n")
  end
end
