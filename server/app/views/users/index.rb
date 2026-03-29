# frozen_string_literal: true

class Views::Users::Index < Views::Base
  prop :users, _Any
  prop :page, Integer, default: 1
  prop :total_pages, Integer, default: 1
  prop :query, _Nilable(String), default: nil
  prop :active_conversation_user_ids, _Any, default: [].freeze

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: Current.user, active_nav: :users) do
      render Components::Panel.new(title: "Users") do
        form action: users_path, method: :get, class: "mb-4" do
          Row gap: 2 do
            Input name: "q", placeholder: "Search by name or UID...", value: @query
            Button label: "Search", variant: :primary
          end
        end

        div class: "user-list" do
          if @users.any?
            @users.each { |user| render_user(user) }
          else
            p(class: "text-muted") { "No users found." }
          end
        end

        if @total_pages > 1
          Row justify: "center", gap: 2 do
            if @page > 1
              a(href: users_path(page: @page - 1, q: @query), class: "btn btn-secondary btn-sm") { "< Prev" }
            end
            span(class: "text-muted") { "Page #{@page} of #{@total_pages}" }
            if @page < @total_pages
              a(href: users_path(page: @page + 1, q: @query), class: "btn btn-secondary btn-sm") { "Next >" }
            end
          end
        end
      end
    end
  end

  private

  def render_user(user)
    css = ["conversation-item"]
    css << "conversation-item--unread" if @active_conversation_user_ids.include?(user.id)

    a href: user_path(user), class: css.join(" ") do
      StatusBar do |bar|
        bar.item state: user.state_color do
          span(class: "font-bold") { user.name }
        end
      end
      span(class: "conversation-participant") { user.human? ? "Human" : "Synthetic" }
      span(class: "conversation-status") { user.state.humanize }
    end
  end
end
