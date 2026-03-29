# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  prop :user, User
  prop :conversations, _Any, default: [].freeze
  prop :tasks, _Any, default: [].freeze
  prop :all_users, _Any, default: [].freeze

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user) do
      Components::SystemPanel(title: "Welcome back #{@user}", subtitle: "Human \u2194 Agent Interface Protocol") do
        Terminal do |terminal|
          terminal.bright_line { "HUBSYSTEM INTERFACE TERMINAL v1.0" }
          terminal.line { "MU/TH/UR 6000 BIOS rev 4.2.1" }
          terminal.line { "#{@conversations.count} active conversation(s)" }
          terminal.line { "#{@tasks.count} task(s) assigned" }
          terminal.bright_line do
            plain "SYSTEM READY"
            span(class: "cursor")
          end
        end
      end

      render Components::Panel.new(title: "Conversations") do
        render Components::ConversationMatrix.new(user: @user, conversations: @conversations)
      end

      render Components::Panel.new(title: "User Activity") do
        render Components::UserActivityMatrix.new(users: @all_users)
      end

      if @tasks.any?
        render Components::Panel.new(title: "Tasks") do
          StatusBar do |status|
            pending_count = @tasks.count(&:pending?)
            blocked_count = @tasks.count(&:blocked?)
            due_count = @tasks.count { |t| t.due_at.present? && t.due_at <= Time.current }

            status.item label: "#{pending_count} Pending", state: :nominal
            status.item label: "#{blocked_count} Blocked", state: (blocked_count > 0) ? :warning : :nominal
            status.item label: "#{due_count} Overdue", state: (due_count > 0) ? :critical : :nominal
          end
        end
      end
    end
  end
end
