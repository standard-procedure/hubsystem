# frozen_string_literal: true

class Views::Users::Show < Views::Base
  prop :user, User
  prop :notes, _Any

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: Current.user, active_nav: :users) do
      render Components::SystemPanel.new(title: @user.name, subtitle: @user.human? ? "Human" : "Synthetic") do
        render_profile
      end

      render Components::Panel.new(title: "Notes") do
        if @notes.any?
          @notes.each { |note| render_note(note) }
        else
          p(class: "text-muted") { "No notes yet." }
        end
        Row justify: "end" do
          Button label: "Add Note", variant: :primary, tag: :a, href: new_user_note_path(@user)
        end
      end

      Row justify: "end", gap: 2 do
        Button label: "Start Conversation", variant: :primary, tag: :a, href: new_user_conversation_path(@user)
        Button label: "Back to Users", variant: :secondary, tag: :a, href: users_path
      end
    end
  end

  private

  def render_profile
    StatusBar do |bar|
      bar.item(state: @user.state_color, label: @user.state.humanize)
      bar.item(state: :info, label: @user.uid)
    end

    if @user.synthetic?
      render Components::Panel.new(title: "Synthetic Profile", variant: :active) do
        p { "Class: #{@user.synthetic_class&.name || "Unassigned"}" }
        p { "Personality: #{@user.personality}" }
        p { "LLM Tier: #{@user.llm_tier}" }
      end
    end
  end

  def render_note(note)
    div class: "conversation-item" do
      p { note.content }
      Row justify: "between" do
        span(class: "text-muted text-sm") do
          plain "#{note.author.name} · #{note.public_note? ? "Public" : "Private"} · #{note.updated_at.strftime("%d %b %Y")}"
        end
        if note.author == Current.user
          Row gap: 1 do
            a(href: edit_user_note_path(@user, note), class: "btn btn-ghost btn-sm") { "Edit" }
            form(action: user_note_path(@user, note), method: :post, style: "display:inline") do
              input type: "hidden", name: "_method", value: "delete"
              input type: "hidden", name: "authenticity_token", value: form_authenticity_token
              Button label: "Delete", variant: :danger, size: :sm
            end
          end
        end
      end
    end
  end
end
