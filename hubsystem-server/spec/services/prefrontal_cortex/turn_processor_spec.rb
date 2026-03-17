require "rails_helper"

RSpec.describe PrefrontalCortex::TurnProcessor do
  let(:processor) { described_class.new }
  let(:agent) do
    create(:agent_participant,
           description: "I am a helpful assistant.",
           agent_class: "HelpBot",
           emotion_parameters: { "happy" => 80, "anxious" => 5, "focused" => 90, "exhausted" => 10, "irritated" => 5 })
  end
  let(:sender) { create(:human_participant) }
  let(:inbound_message) do
    msg = create(:message, from: sender, to: agent)
    msg.parts.create!(content_type: "text/plain", body: "Hello, agent!", position: 0)
    msg
  end
  let(:memories) { [] }
  let(:captured) { {} }

  before do
    allow(LLMProvider).to receive(:for_role).with(:main_turn).and_return(
      ->(system_prompt, context) {
        captured[:system_prompt] = system_prompt
        captured[:context] = context
        "I am here to help!"
      }
    )
    # L0 retrieval inside build_system_prompt returns empty in clean test DB
  end

  describe "#process" do
    it "calls the LLM provider" do
      expect(LLMProvider).to receive(:for_role).with(:main_turn).and_call_original
      allow(LLMProvider).to receive(:for_role).with(:main_turn).and_return(
        ->(_sp, _ctx) { "Response text" }
      )
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
    end

    it "includes the agent description in the system prompt" do
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(captured[:system_prompt]).to include("I am a helpful assistant.")
    end

    it "includes the agent_class in the system prompt" do
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(captured[:system_prompt]).to include("HelpBot")
    end

    it "includes emotional state summary in the system prompt" do
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(captured[:system_prompt]).to include("happy")
      expect(captured[:system_prompt]).to include("80")
    end

    it "includes the inbound message text in the context" do
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(captured[:context]).to include("Hello, agent!")
    end

    it "includes memories as bullet points in context" do
      memories_with_content = [
        build_stubbed(:memory, content: "The user prefers short answers.", excerpt: nil, summary: nil),
        build_stubbed(:memory, content: "Previous topic was Ruby.", excerpt: nil, summary: nil)
      ]
      processor.process(agent: agent, inbound_message: inbound_message, memories: memories_with_content)
      expect(captured[:context]).to include("The user prefers short answers.")
      expect(captured[:context]).to include("Previous topic was Ruby.")
    end

    it "creates and returns a reply Message" do
      reply = processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(reply).to be_a(Message)
    end

    it "sets the reply from the agent" do
      reply = processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(reply.from).to eq(agent)
    end

    it "sets the reply to the original sender" do
      reply = processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      expect(reply.to).to eq(sender)
    end

    it "creates a text/markdown MessagePart with the LLM response" do
      reply = processor.process(agent: agent, inbound_message: inbound_message, memories: memories)
      part = reply.parts.first
      expect(part.content_type).to eq("text/markdown")
      expect(part.body).to eq("I am here to help!")
    end

    it "preserves the conversation on the reply" do
      conversation = create(:conversation)
      inbound_message.update!(conversation: conversation)
      reply = processor.process(agent: agent, inbound_message: inbound_message,
                                memories: memories, conversation: conversation)
      expect(reply.conversation).to eq(conversation)
    end
  end
end
