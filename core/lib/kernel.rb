module Kernel
  def Await(&block)
    result = block.call
    result.respond_to?(:wait) ? result.wait : result
  end
  alias_method :await, :Await
end
