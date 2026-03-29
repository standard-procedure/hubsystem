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

# Suppress background jobs during seeding (avoid LLM token usage)
ActiveJob::Base.queue_adapter = :test

# Conversations
alice_bob = Conversation.between(alice, bob).open.first || Conversation.create!(
  initiator: alice, recipient: bob, subject: "Deployment planning", status: :active
)

if alice_bob.messages.empty?
  alice_bob.messages.create!(sender: alice, content: "Hey Bob, have you had a chance to look at the deployment checklist?", created_at: 2.hours.ago)
  alice_bob.messages.create!(sender: bob, content: "Yeah, I went through it this morning. A couple of things stood out.", created_at: 1.hour.ago + 50.minutes)
  alice_bob.messages.create!(sender: alice, content: "Oh? What did you find?", created_at: 1.hour.ago + 48.minutes)
  alice_bob.messages.create!(sender: bob, content: "The rollback procedure references the old database schema. We need to update it for the new delegated types migration.", created_at: 1.hour.ago + 45.minutes)
  alice_bob.messages.create!(sender: alice, content: "Good catch. Can you draft the updated version?", created_at: 1.hour.ago + 42.minutes)
  alice_bob.messages.create!(sender: bob, content: "Already on it. I'll have it ready by end of day.", created_at: 1.hour.ago + 40.minutes)
  alice_bob.messages.create!(sender: alice, content: "Great. Also, we should check the Ollama sidecar config before we push to staging.", created_at: 1.hour.ago + 35.minutes)
  alice_bob.messages.create!(sender: bob, content: "Agreed. I noticed the model pull step isn't in the postCreateCommand for staging. Only dev.", created_at: 1.hour.ago + 30.minutes)
  alice_bob.messages.create!(sender: alice, content: "Right, staging uses the Anthropic API directly. We just need to make sure the API key is in credentials.", created_at: 1.hour.ago + 25.minutes)
  alice_bob.messages.create!(sender: bob, content: "I'll verify that. Anything else blocking the deploy?", created_at: 1.hour.ago + 20.minutes)
  alice_bob.messages.create!(sender: alice, content: "I don't think so. Let's aim for tomorrow morning if the checklist is sorted.", created_at: 1.hour.ago + 15.minutes)
  alice_bob.messages.create!(sender: bob, content: "Sounds good. I'll ping you once the rollback doc is updated.", created_at: 1.hour.ago + 10.minutes)
end

# Set some users online for demo
User.find_by(uid: "alice")&.go_online!
User.find_by(uid: "bob")&.go_online!
User.find_by(uid: "bishop")&.update!(state: "online")
User.find_by(uid: "call")&.update!(state: "busy")
User.find_by(uid: "david").update!(state: "online")
User.find_by(uid: "ash")&.update!(state: "tired")
