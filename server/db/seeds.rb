alice = User::Human.where(uid: "alice").first_or_create!(name: "Alice Aardvark")
alice.identities.where(provider: "developer", uid: "alice").first_or_create!

bob = User.find_by(uid: "bob") || User::Human.create!(uid: "bob", name: "Bob Badger")
bob.identities.where(provider: "developer", uid: "bob").first_or_create! if bob.is_a?(User::Human)

User::Human.where(uid: "charlie").first_or_create!(name: "Charlie Cheetah")
User::Human.where(uid: "dave").first_or_create!(name: "Dave Dolphin")
User::Human.where(uid: "eve").first_or_create!(name: "Eve Eagle")
User::Human.where(uid: "frank").first_or_create!(name: "Frank Falcon")

User::Synthetic.where(uid: "bishop").first_or_create!(name: "Bishop", personality: "Calm and methodical")
User::Synthetic.where(uid: "ash").first_or_create!(name: "Ash", personality: "Direct and efficient")
User::Synthetic.where(uid: "call").first_or_create!(name: "Call", personality: "Curious and empathetic")
