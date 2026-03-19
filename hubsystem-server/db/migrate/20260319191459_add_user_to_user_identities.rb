class AddUserToUserIdentities < ActiveRecord::Migration[8.1]
  def change
    add_reference :user_identities, :user, null: false, foreign_key: true
  end
end
