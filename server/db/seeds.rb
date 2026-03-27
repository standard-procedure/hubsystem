alice = User::Human.where(uid: "alice").first_or_create!(name: "Alice Aardvark")
alice_identity = alice.identities.where(provider: "developer", uid: "alice").first_or_create!

bob = User::Synthetic.where(uid: "bob").first_or_create!(name: "Bob Robot", personality: "Calm")
