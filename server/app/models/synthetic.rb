# frozen_string_literal: true

class Synthetic < ApplicationRecord
  has_one :user, as: :role, dependent: :destroy, touch: true
  has_one :llm_context, dependent: :destroy
  has_many :memories, class_name: "Synthetic::Memory", dependent: :destroy, inverse_of: :synthetic
  belongs_to :synthetic_class, optional: true

  EMOTIONS = %w[joy sadness fear anger surprise disgust anticipation trust].freeze

  def llm_tier
    synthetic_class&.llm_tier || "low"
  end

  def operating_system
    synthetic_class&.operating_system || ""
  end

  def ensure_llm_context
    llm_context || create_llm_context!(llm_model: default_llm_model)
  end

  def default_llm_model
    config = Rails.application.config.llm_models[llm_tier.to_sym]
    LlmModel.find_by(model_id: config[:model], provider: config[:provider])
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
