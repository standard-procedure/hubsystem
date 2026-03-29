# frozen_string_literal: true

class Synthetic
  class CapacityEvaluator < BaseModule
    COMPACTION_THRESHOLD = 80
    DEFAULT_CONTEXT_WINDOW = 100_000
    FALLBACK_TOKENS_PER_MESSAGE = 500

    Result = Data.define(:fatigue, :needs_compaction)

    def process
      context = @synthetic.ensure_llm_context
      total_tokens = calculate_tokens(context)
      max_tokens = context_window(context)
      fatigue = ((total_tokens.to_f / max_tokens) * 100).round.clamp(0, 100)

      @synthetic.update!(fatigue: fatigue)

      Result.new(
        fatigue: fatigue,
        needs_compaction: fatigue >= COMPACTION_THRESHOLD
      )
    end

    private

    def calculate_tokens(context)
      messages = context.llm_context_messages
      token_sum = messages.sum(:input_tokens).to_i + messages.sum(:output_tokens).to_i
      # Fall back to estimate if no token data recorded yet
      (token_sum > 0) ? token_sum : messages.count * FALLBACK_TOKENS_PER_MESSAGE
    end

    def context_window(context)
      context.llm_model&.context_window || DEFAULT_CONTEXT_WINDOW
    end
  end
end
