# frozen_string_literal: true

class User::Synthetic < User
  has_attribute :personality, :string, default: ""
  has_attribute :temperature, :decimal, default: 0.4
  has_attribute :fatigue, :integer, default: 0
  has_attribute :emotions, :json, default: {
    "joy" => 50, "sadness" => 10, "fear" => 10, "anger" => 10,
    "surprise" => 20, "disgust" => 5, "anticipation" => 30, "trust" => 50
  }.freeze

  has_one :llm_context, class_name: "LlmContext", foreign_key: :user_id, dependent: :destroy

  EMOTIONS = %w[joy sadness fear anger surprise disgust anticipation trust].freeze

  def ensure_llm_context
    llm_context || create_llm_context!
  end

  def adjust_emotions(deltas)
    current = emotions.stringify_keys
    deltas.each do |emotion, delta|
      key = emotion.to_s
      next unless EMOTIONS.include?(key)
      current[key] = (current[key].to_i + delta.to_i).clamp(0, 100)
    end
    self.emotions = current
    save!
  end
end
