# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  prop :user, User
  prop :unread_messages, ActiveRecord::Relation(Conversation::Message)
  prop :all_users, ActiveRecord::Relation(User)

  def view_template
    render Views::Layouts::Application.new(title: t("application.title"), user: @user, nav_active: :dashboard) do
      Column justify: "between", class: %w[grow-1] do
        SystemPanel(title: "Welcome back #{@user}", subtitle: "Human \u2194 Agent Interface Protocol") do
          Terminal do |terminal|
            terminal.bright_line { "HUBSYSTEM INTERFACE TERMINAL v1.0" }
            terminal.line { "MU/TH/UR 6000 BIOS rev 4.2.1" }
            terminal.line { unread_message_label }
            terminal.bright_line do
              plain "SYSTEM READY"
              span(class: "cursor")
            end
          end
        end

        Panel(title: Conversation::Message.pn) do
          Row justify: "between" do
            StatusItem(state: unread_message_state, label: unread_message_label)
            UserActivityMatrix(users: @all_users)
          end
        end
      end
    end
  end

  private def unread_message_state = @unread_messages.any? ? :alert : :online
  private def unread_message_label = t(".unread_messages", count: @unread_messages.size)
end
