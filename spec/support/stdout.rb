# frozen_string_literal: true

require "stringio"

module RSpec
  module Support
    module Stdout
      private

      class TTYStream < StringIO
        def tty?
          true
        end
      end

      def with_captured_stdout
        original = $stdout
        captured = StringIO.new
        $stdout  = captured
        yield
        $stdout.string
      ensure
        $stdout = original
      end

      # TODO: unify these two helpers
      def with_tty
        original = $stdout
        captured = TTYStream.new
        $stdout  = captured
        yield
        $stdout.string
      ensure
        $stdout.close
        $stdout = original
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Stdout
end
