class AgentPipeline
  def initialize(
    threat_evaluator: nil,
    authorisation_checker: nil,
    emotion_updater: nil,
    exhaustion_monitor: nil,
    memory_retriever: nil,
    turn_processor: nil,
    memory_writer: nil
  )
    @threat_evaluator = threat_evaluator || Amygdala::ThreatEvaluator.new
    @authorisation_checker = authorisation_checker || Amygdala::AuthorisationChecker.new
    @emotion_updater = emotion_updater || Amygdala::EmotionUpdater.new
    @exhaustion_monitor = exhaustion_monitor || Brainstem::ExhaustionMonitor.new
    @memory_retriever = memory_retriever || Hippocampus::MemoryRetriever.new
    @turn_processor = turn_processor || PrefrontalCortex::TurnProcessor.new
    @memory_writer = memory_writer || Hippocampus::MemoryWriter.new
  end

  def process(inbound_message)
    agent = inbound_message.to

    # Step 1: Only process AgentParticipant recipients
    return nil unless agent.is_a?(AgentParticipant)

    # Step 2: Authorisation check
    return nil if @authorisation_checker.check(inbound_message.from, agent) == :denied

    # Step 3: Threat evaluation
    threat_result = @threat_evaluator.evaluate(inbound_message, agent)
    if threat_result == :do_not_process
      inbound_message.update!(flagged: true)
      @emotion_updater.update(agent, inbound_message, direction: :do_not_process)
      return nil
    elsif threat_result == :dodgy
      inbound_message.update!(flagged: true)
    end

    # Step 4: Pre-turn exhaustion check
    return nil if @exhaustion_monitor.check(agent)

    agent.reload

    # Step 5: Memory retrieval
    query = inbound_message.parts.map(&:body).join(" ")
    memories = @memory_retriever.retrieve(agent: agent, query: query)

    # Step 6: Turn processing
    response = @turn_processor.process(
      agent: agent,
      inbound_message: inbound_message,
      memories: memories,
      conversation: inbound_message.conversation
    )

    # Step 7: Write memory
    @memory_writer.write(participant: agent, content: query)

    # Step 8: Emotion update inbound
    agent.reload
    @emotion_updater.update(agent, inbound_message, direction: :inbound)

    # Step 9: Emotion update outbound
    agent.reload
    @emotion_updater.update(agent, response, direction: :outbound)

    # Step 10: Post-turn exhaustion check
    agent.reload
    @exhaustion_monitor.check(agent)

    response
  end
end
