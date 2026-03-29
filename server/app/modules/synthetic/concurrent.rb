# frozen_string_literal: true

require "async"
require "async/barrier"

module Synthetic
  module Concurrent
    def self.run(*callables)
      results = Array.new(callables.size)
      Sync do
        barrier = Async::Barrier.new
        callables.each_with_index do |callable, i|
          barrier.async { results[i] = callable.call }
        end
        barrier.wait
      end
      results
    end
  end
end
