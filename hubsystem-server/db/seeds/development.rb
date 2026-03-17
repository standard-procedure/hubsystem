# 5-8 named agents with distinct personalities and agent classes
agents = [
  { name: "Aria",  slug: "aria",  agent_class: "SupportAgent",   description: "Warm and patient. Specialises in helping humans navigate complex situations. Likes: clear questions, people who say thank you. Dislikes: vague requests." },
  { name: "Rex",   slug: "rex",   agent_class: "SecurityAgent",  description: "Precise and cautious. Takes security seriously but not humourlessly. Likes: well-specified permissions. Dislikes: corner-cutting." },
  { name: "Nova",  slug: "nova",  agent_class: "ResearchAgent",  description: "Curious and thorough. Loves diving deep into topics. Likes: interesting problems, citations. Dislikes: being rushed." },
  { name: "Clio",  slug: "clio",  agent_class: "MemoryAgent",    description: "Quiet and methodical. Excellent at finding patterns across conversations. Likes: well-tagged memories. Dislikes: ambiguous context." },
  { name: "Dex",   slug: "dex",   agent_class: "DevAgent",       description: "Pragmatic and fast. Writes scripts first, asks questions later. Likes: bash, working code. Dislikes: meetings." },
]

agents.each do |attrs|
  AgentParticipant.find_or_create_by!(slug: attrs[:slug]) do |a|
    a.name = attrs[:name]
    a.agent_class = attrs[:agent_class]
    a.description = attrs[:description]
  end
end

# Human participant for Baz
baz = HumanParticipant.find_or_create_by!(slug: "baz") do |h|
  h.name = "Baz"
  h.description = "The developer. Curious, direct, occasionally impatient."
end

# Default group — everyone can message everyone
group = Group.find_or_create_by!(slug: "default") do |g|
  g.name = "Default"
  g.group_type = "account"
end

# Security passes for all
Participant.all.each do |p|
  SecurityPass.find_or_create_by!(participant: p, group: group) do |sp|
    sp.capabilities = ["message"]
  end
end

# Give Dex bash capability (find_or_create won't update existing — handle separately)
dex = AgentParticipant.find_by!(slug: "dex")
dex_pass = SecurityPass.find_or_initialize_by(participant: dex, group: group)
dex_pass.capabilities = ["message", "bash"]
dex_pass.save!

puts ""
puts "=== HubSystem Development Seeds ==="
puts ""
puts "Agents: #{AgentParticipant.pluck(:name).join(', ')}"
puts ""
puts "Your token (Baz):"
puts "  export HUBSYSTEM_TOKEN=#{baz.token}"
puts "  export HUBSYSTEM_URL=http://localhost:3000"
puts ""
puts "Try: hubsystem participants"
puts "     hubsystem send --to=aria --message='Hello Aria'"
puts "     hubsystem inbox"
puts ""
