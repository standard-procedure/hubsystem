# frozen_string_literal: true

class Views::Conversations::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :users, _Any
  prop :selected_user, _Nilable(User), default: nil
  prop :query, String, default: ""

  def view_template
    render Views::Layouts::Application.new(title: t(".title"), return_href: conversations_path, user: @user, nav_active: :messages, nav_alerts: []) do
      Panel(title: t(".title")) do
        Column gap: 4 do
          render_user_search
          render_user_results if @users.any?
          render_conversation_form if @selected_user || @users.any?
        end
      end
    end
  end

  private

  def render_user_search
    form action: new_conversation_path, method: :get do
      Row justify: "between", wrap: false, gap: 2 do
        Input name: "q", placeholder: t(".search_placeholder"), value: @query
        Button label: t(".search"), variant: :secondary
      end
    end
  end

  def render_user_results
    div class: "user-list" do
      @users.reject { |u| u == @user }.each do |u|
        render_user_option(u)
      end
    end
  end

  def render_conversation_form
    form_with url: conversations_path, method: :post do |form|
      Column gap: 4 do
        if @selected_user
          render_selected_user(@selected_user)
          form.hidden_field :participant_ids, value: @selected_user.id, name: "conversation[participant_ids][]"
        end
        Input name: "conversation[subject]", label: Conversation.an(:subject), placeholder: t(".subject_placeholder"), required: true
        Input name: "conversation[message]", label: Conversation::Message.fn, placeholder: t(".message_placeholder"), required: true
        Row justify: "end" do
          Button label: t(".send"), variant: :primary
        end
      end
    end
  end

  def render_user_option(user)
    selected = @selected_user == user
    css = ["conversation-item"]
    css << "conversation-item--unread" if selected
    a href: new_conversation_path(with: user.id, q: @query), class: css do
      h2 { user.name }
    end
  end

  def render_selected_user(user)
    div class: "conversation-item conversation-item--unread" do
      h2 { user.name }
    end
  end
end
