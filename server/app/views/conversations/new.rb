# frozen_string_literal: true

class Views::Conversations::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :users, _Any
  prop :selected_user, _Nilable(User), default: nil
  prop :query, String, default: ""

  def view_template
    render Views::Layouts::Application.new(title: t(".title"), return_href: conversations_path, user: @user, nav_active: :messages, nav_alerts: []) do
      Column justify: "between", class: %w[grow-1] do
        Column do
          Switcher do
            Messages::TabBar user: @user, active: :conversations
            render_user_search
          end
          if @selected_user
            render_conversation_form
          elsif @users.any?
            render_user_results
          elsif @query.present?
            Panel(title: t(".no_results_title")) do
              p(class: "text-muted") { t(".no_results", query: @query) }
            end
          else
            Panel(title: t(".title")) do
              p(class: "text-muted") { t(".get_started", query: @query) }
            end
          end
        end
      end
    end
  end

  private

  def render_user_search
    form action: new_conversation_path, method: :get do
      Row justify: "between", wrap: false, gap: 2 do
        Input name: "q", placeholder: t(".search_placeholder"), value: @query
        Button label: t(".search"), variant: ((@selected_user.nil? && @users.empty?) ? :primary : :secondary)
      end
    end
  end

  def render_user_results
    Grid(
      columns: [
        Components::Grid::Column.new(label: t(".user_name"), width: 3),
        Components::Grid::Column.new(label: t(".user_status"), width: 1)
      ],
      max_height: "400px"
    ) do |grid|
      @users.reject { |u| u == @user }.each do |u|
        grid.row(
          {value: u.name, href: new_conversation_path(with: u.id, q: @query), color: :phosphor},
          {value: u.status_badge.humanize, href: new_conversation_path(with: u.id, q: @query)}
        )
      end
    end
  end

  def render_conversation_form
    Panel(title: t(".start_with", name: @selected_user.name), variant: :active) do
      form_with url: conversations_path, method: :post do |form|
        Column gap: 4 do
          form.hidden_field :participant_ids, value: @selected_user.id, name: "conversation[participant_ids][]"
          Input name: "conversation[subject]", label: Conversation.an(:subject), placeholder: t(".subject_placeholder"), required: true
          Input name: "conversation[message]", label: Conversation::Message.fn, placeholder: t(".message_placeholder"), required: true
          Row justify: "between" do
            Button href: new_conversation_path, label: t("application.cancel"), variant: :ghost
            Button label: t(".send"), variant: :primary
          end
        end
      end
    end
  end
end
