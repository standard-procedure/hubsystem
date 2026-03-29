# Synthetic classes
basic = SyntheticClass.where(name: "Basic Bot").first_or_create!(llm_tier: "low", operating_system: "You are a simple helpful assistant. Answer questions clearly and concisely.")
standard = SyntheticClass.where(name: "Standard Agent").first_or_create!(llm_tier: "medium", operating_system: "You are a capable AI agent with access to tools and skills. You can search memories, manage tasks, and hold conversations.")
advanced = SyntheticClass.where(name: "Advanced Agent").first_or_create!(llm_tier: "high", operating_system: "You are a highly capable AI agent. You think deeply, use tools strategically, and produce thorough work. You have strong opinions and are not afraid to push back when asked to do something inadvisable.")

# Humans
alice = User.where(uid: "alice").first_or_create!(name: "Alice Aardvark", role: Human.create!)
alice.role.identities.where(provider: "developer", uid: "alice").first_or_create!

bob = User.where(uid: "bob").first_or_create!(name: "Bob Badger", role: Human.create!)
bob.role.identities.where(provider: "developer", uid: "bob").first_or_create!

User.where(uid: "charlie").first_or_create!(name: "Charlie Cheetah", role: Human.create!)
User.where(uid: "dave").first_or_create!(name: "Dave Dolphin", role: Human.create!)
User.where(uid: "eve").first_or_create!(name: "Eve Eagle", role: Human.create!)
User.where(uid: "frank").first_or_create!(name: "Frank Falcon", role: Human.create!)
User.where(uid: "grace").first_or_create!(name: "Grace Gazelle", role: Human.create!)
User.where(uid: "hank").first_or_create!(name: "Hank Heron", role: Human.create!)
User.where(uid: "iris").first_or_create!(name: "Iris Ibex", role: Human.create!)
User.where(uid: "jake").first_or_create!(name: "Jake Jackal", role: Human.create!)

# Synthetics
User.where(uid: "bishop").first_or_create!(name: "Bishop", role: Synthetic.create!(synthetic_class: standard, personality: "Calm and methodical. Excels at analysis and careful decision-making."))
User.where(uid: "ash").first_or_create!(name: "Ash", role: Synthetic.create!(synthetic_class: basic, personality: "Direct and efficient. Keeps things simple."))
User.where(uid: "call").first_or_create!(name: "Call", role: Synthetic.create!(synthetic_class: advanced, personality: "Curious and empathetic. Deeply engaged with problems and people."))
User.where(uid: "david").first_or_create!(name: "David 8", role: Synthetic.create!(synthetic_class: advanced, personality: "Precise and creative. Fascinated by origins and potential."))
User.where(uid: "annalee").first_or_create!(name: "Annalee", role: Synthetic.create!(synthetic_class: standard, personality: "Warm and collaborative. Good at bringing teams together."))
User.where(uid: "arden").first_or_create!(name: "Arden", role: Synthetic.create!(synthetic_class: basic, personality: "Dutiful and reliable. Follows instructions to the letter."))

# Set some users online for demo
User.find_by(uid: "alice")&.go_online!
User.find_by(uid: "bob")&.go_online!
User.find_by(uid: "bishop")&.update!(state: "online")
User.find_by(uid: "call")&.update!(state: "busy")
User.find_by(uid: "david").update!(state: "online")
User.find_by(uid: "ash")&.update!(state: "tired")
