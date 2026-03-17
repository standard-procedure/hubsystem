module Brainstem
  class CompactionJob < ApplicationJob
    queue_as :default

    def perform(agent_id)
      agent = AgentParticipant.find(agent_id)
      params = agent.emotion_parameters.dup
      params["exhausted"] = 0
      agent.update!(state: "awake", emotion_parameters: params)
    end
  end
end
