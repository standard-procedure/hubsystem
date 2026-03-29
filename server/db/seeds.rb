# Synthetic classes
basic = SyntheticClass.where(name: "Basic Bot").first_or_create!(llm_tier: "low", operating_system: "You are a simple helpful assistant.")
standard = SyntheticClass.where(name: "Standard Agent").first_or_create!(llm_tier: "medium", operating_system: "You are a capable AI agent with access to tools and skills.")
advanced = SyntheticClass.where(name: "Advanced Agent").first_or_create!(llm_tier: "high", operating_system: "You are a highly capable AI agent. You think deeply, use tools strategically, and produce thorough work.")

# Humans
alice = User.where(uid: "alice").first_or_create!(name: "Alice Aardvark", role: Human.create!)
alice.role.identities.where(provider: "developer", uid: "alice").first_or_create!

bob = User.where(uid: "bob").first_or_create!(name: "Bob Badger", role: Human.create!)
bob.role.identities.where(provider: "developer", uid: "bob").first_or_create!

User.where(uid: "charlie").first_or_create!(name: "Charlie Cheetah", role: Human.create!)
User.where(uid: "dave").first_or_create!(name: "Dave Dolphin", role: Human.create!)
User.where(uid: "eve").first_or_create!(name: "Eve Eagle", role: Human.create!)
User.where(uid: "frank").first_or_create!(name: "Frank Falcon", role: Human.create!)

# Synthetics
User.where(uid: "bishop").first_or_create!(name: "Bishop", role: Synthetic.create!(synthetic_class: standard, personality: "Calm and methodical"))
User.where(uid: "ash").first_or_create!(name: "Ash", role: Synthetic.create!(synthetic_class: basic, personality: "Direct and efficient"))
User.where(uid: "call").first_or_create!(name: "Call", role: Synthetic.create!(synthetic_class: advanced, personality: "Curious and empathetic"))
