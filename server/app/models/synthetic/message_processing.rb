class Synthetic
  module MessageProcessing
    extend ActiveSupport::Concern

    def receive message
      message.reply sender: user, content: pipeline.process(message)
    end

    def pipeline
      Synthetic::Pipeline.new(synthetic: self)
    end

    def prompt_for(message)
      <<~PROMPT
        # Message details
        
        Message received from #{message.sender.name} (UID #{message.sender.uid}) at #{message.created_at}: 

        <message-content>
        #{message.content}
        </message-content>
      PROMPT
    end

    def system_prompt
      <<~PROMPT
        You are a synthetic person called #{user.name} (UID #{user.uid}).

        Your personality, emotional state and fatigue levels will colour your responses to any messages that you receive.

        # Personality

        #{personality}

        ## Operating Parameters

        #{operating_system}
        
        ## Emotional state
        ```json
        #{emotions.to_json}
        ```
                
        ## Fatigue level
        ```json 
        { "fatigue": #{fatigue} }
        ```
        
        Values are between 0 and 100 - for example: `{ "happiness": 75, "fear": 10 }` means you are very happy and slightly fearful.
        
      PROMPT
    end
  end
end
