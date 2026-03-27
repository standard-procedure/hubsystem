# frozen_string_literal: true

class Components::Terminal < Components::Slotted
  class Line < Literal::Data
    prop :bright, _Boolean, default: false
    prop :contents, _Callable
  end

  def initialize(...)
    @lines = []
    super
  end

  def line(bright: false, &contents)
    @lines << Line.new(bright:, contents:)
  end

  def bright_line(&contents) = line(bright: true, &contents)

  def view_template(&contents)
    vanish
    @contents&.call
    @lines.each_with_index do |line, line_number|
      div(class: class_for(line), style: "animation-delay: #{delay_for(line_number)}", &line.contents)
    end
  end

  private def class_for(line) = line.bright ? ["boot-line"] : ["boot-line", "boot-line--dim"]
  private def delay_for(number) = "#{number * 0.1}s"
end
