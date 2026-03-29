# frozen_string_literal: true

class Synthetic < ApplicationRecord
  has_one :user, as: :role, dependent: :destroy, touch: true
  has_one :llm_context, dependent: :destroy
  has_many :memories, class_name: "Synthetic::Memory", dependent: :destroy, inverse_of: :synthetic

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
