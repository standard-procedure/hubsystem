# Humans
alice = User.where(uid: "alice").first_or_create!(name: "Alice Aardvark")
alice.identities.where(provider: "developer", uid: "alice").first_or_create!

bob = User.where(uid: "bob").first_or_create!(name: "Bob Badger")
bob.identities.where(provider: "developer", uid: "bob").first_or_create!

User.where(uid: "charlie").first_or_create!(name: "Charlie Cheetah")
User.where(uid: "dave").first_or_create!(name: "Dave Dolphin")
User.where(uid: "eve").first_or_create!(name: "Eve Eagle")
User.where(uid: "frank").first_or_create!(name: "Frank Falcon")
User.where(uid: "grace").first_or_create!(name: "Grace Gazelle")
User.where(uid: "hank").first_or_create!(name: "Hank Heron")
User.where(uid: "iris").first_or_create!(name: "Iris Ibex")
User.where(uid: "jake").first_or_create!(name: "Jake Jackal")

# Suppress background jobs during seeding (avoid LLM token usage)
ActiveJob::Base.queue_adapter = :test

# Conversations
alice_bob = alice.start_conversation message: "Deployment planning", with: bob

if alice_bob.messages.empty?
  alice_bob.messages.create!(sender: alice, contents: "Hey Bob, have you had a chance to look at the deployment checklist?", created_at: 2.hours.ago)
  alice_bob.messages.create!(sender: bob, contents: "Yeah, I went through it this morning. A couple of things stood out.", created_at: 1.hour.ago + 50.minutes)
  alice_bob.messages.create!(sender: alice, contents: "Oh? What did you find?", created_at: 1.hour.ago + 48.minutes)
  alice_bob.messages.create!(sender: bob, contents: "The rollback procedure references the old database schema. We need to update it for the new delegated types migration.", created_at: 1.hour.ago + 45.minutes)
  alice_bob.messages.create!(sender: alice, contents: "Good catch. Can you draft the updated version?", created_at: 1.hour.ago + 42.minutes)
  alice_bob.messages.create!(sender: bob, contents: "Already on it. I'll have it ready by end of day.", created_at: 1.hour.ago + 40.minutes)
  alice_bob.messages.create!(sender: alice, contents: "Great. Also, we should check the Ollama sidecar config before we push to staging.", created_at: 1.hour.ago + 35.minutes)
  alice_bob.messages.create!(sender: bob, contents: "Agreed. I noticed the model pull step isn't in the postCreateCommand for staging. Only dev.", created_at: 1.hour.ago + 30.minutes)
  alice_bob.messages.create!(sender: alice, contents: "Right, staging uses the Anthropic API directly. We just need to make sure the API key is in credentials.", created_at: 1.hour.ago + 25.minutes)
  alice_bob.messages.create!(sender: bob, contents: "I'll verify that. Anything else blocking the deploy?", created_at: 1.hour.ago + 20.minutes)
  alice_bob.messages.create!(sender: alice, contents: "I don't think so. Let's aim for tomorrow morning if the checklist is sorted.", created_at: 1.hour.ago + 15.minutes)
  alice_bob.messages.create!(sender: bob, contents: "Sounds good. I'll ping you once the rollback doc is updated.", created_at: 1.hour.ago + 10.minutes)
end
