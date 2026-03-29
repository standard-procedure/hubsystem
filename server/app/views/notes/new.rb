# frozen_string_literal: true

class Views::Notes::New < Views::Base
  prop :user, User
  prop :note, _Nilable(Note), default: nil

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: Current.user, active_nav: :users) do
      render Components::Panel.new(title: "New Note about #{@user.name}") do
        render_form(user_notes_path(@user))
      end
    end
  end

  private

  def render_form(action)
    form action: action, method: :post do
      input type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token
      Column gap: 4 do
        Input name: "note[content]", type: "textarea", label: "Note", required: true,
          value: @note&.content,
          error: @note&.errors&.[](:content)&.first
        Row gap: 4 do
          label do
            input type: "radio", name: "note[visibility]", value: "private", checked: @note&.public_note? != true
            plain " Private"
          end
          label do
            input type: "radio", name: "note[visibility]", value: "public", checked: @note&.public_note? == true
            plain " Public"
          end
        end
        Row justify: "end", gap: 2 do
          Button label: "Cancel", variant: :secondary, tag: :a, href: user_path(@user)
          Button label: "Save Note", variant: :primary
        end
      end
    end
  end
end
