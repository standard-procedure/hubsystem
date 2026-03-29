# frozen_string_literal: true

module LlmMock
  # Stub RubyLLM.chat to return a mock chat that responds with the given content
  def stub_llm_response(content)
    mock_response = instance_double(RubyLLM::Message, content: content)
    mock_chat = instance_double(RubyLLM::Chat)
    allow(mock_chat).to receive(:with_model).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
    allow(RubyLLM).to receive(:chat).with(any_args).and_return(mock_chat)
    mock_chat
  end
end

RSpec.configure do |config|
  config.include LlmMock, type: :module
end
