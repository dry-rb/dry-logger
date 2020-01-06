# frozen_string_literal: true

require 'pathname'
require 'stringio'

module RSpec
  module Support
    module IO
      private

      def read(stream)
        case stream
        when Pathname
          stream.read
        when StringIO
          stream.rewind
          stream.read
        when ::IO
          raise 'boom'
        end
      end

      def io_stream(destination)
        fd = ::IO.sysopen(destination, 'w')
        ::IO.new(fd, 'w')
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::IO
end
