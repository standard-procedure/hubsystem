# Integration test seed data.
# Loaded by db:reset in the integration environment.
# Creates known participants, a group, and security passes so integration specs
# can run against predictable data.

# A human participant — Baz
baz = HumanParticipant.create!(
  name: "Baz",
  slug: "baz",
  description: "The developer who built this."
)
puts "Human token: #{baz.token}"

# An agent
aria = AgentParticipant.create!(
  name: "Aria",
  slug: "aria",
  agent_class: "GeneralAgent",
  description: "A helpful general-purpose agent."
)

# A group both belong to
group = Group.create!(name: "Default", group_type: "account", slug: "default")

# Security passes
SecurityPass.create!(participant: baz, group: group, capabilities: ["message"])
SecurityPass.create!(participant: aria, group: group, capabilities: ["message"])

# Write token to a temp file so integration specs can read it
File.write("/tmp/hubsystem-integration-baz-token", baz.token)
puts "Token written to /tmp/hubsystem-integration-baz-token"
