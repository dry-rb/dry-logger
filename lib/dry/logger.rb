# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"
require "dry/logger/backends/stream"

module Dry
  module Logger
    include Level

    def self.new(**opts)
      Stream.new(**opts)
    end
  end
end
