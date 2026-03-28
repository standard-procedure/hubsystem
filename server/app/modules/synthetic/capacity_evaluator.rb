# frozen_string_literal: true

module Synthetic
  class CapacityEvaluator < BaseModule
    COMPACTION_THRESHOLD = 80

    Result = Data.define(:fatigue, :needs_compaction)

    def process
      context = @synthetic.ensure_llm_context
      message_count = context.llm_context_messages.count
      # Estimate fatigue as percentage of a reasonable context window
      # Approximate: each message averages ~500 tokens, typical window is ~100k tokens
      estimated_tokens = message_count * 500
      max_tokens = 100_000
      fatigue = ((estimated_tokens.to_f / max_tokens) * 100).round.clamp(0, 100)

      @synthetic.update!(fatigue: fatigue)

      Result.new(
        fatigue: fatigue,
        needs_compaction: fatigue >= COMPACTION_THRESHOLD
      )
    end
  end
end
