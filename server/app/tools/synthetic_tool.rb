# frozen_string_literal: true

class SyntheticTool < RubyLLM::Tool
  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end
end
