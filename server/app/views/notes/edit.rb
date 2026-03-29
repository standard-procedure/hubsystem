# frozen_string_literal: true

class Views::Notes::Edit < Views::Base
  prop :user, User
  prop :note, Note

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: Current.user, active_nav: :users) do
      render Components::Panel.new(title: "Edit Note about #{@user.name}") do
        form action: user_note_path(@user, @note), method: :post do
          input type: "hidden", name: "_method", value: "patch"
          input type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token
          Column gap: 4 do
            Input name: "note[content]", type: "textarea", label: "Note", required: true,
              value: @note.content,
              error: @note.errors[:content]&.first
            Row gap: 4 do
              label do
                input type: "radio", name: "note[visibility]", value: "private", checked: !@note.public_note?
                plain " Private"
              end
              label do
                input type: "radio", name: "note[visibility]", value: "public", checked: @note.public_note?
                plain " Public"
              end
            end
            Row justify: "end", gap: 2 do
              Button label: "Cancel", variant: :secondary, tag: :a, href: user_path(@user)
              Button label: "Update Note", variant: :primary
            end
          end
        end
      end
    end
  end
end
