# frozen_string_literal: true

require "pathname"
require "securerandom"

module RSpec
  module Support
    module Files
      private

      def generate_file(destination, contents)
        mkdir_p(destination)
        File.open(destination, File::WRONLY | File::TRUNC | File::CREAT, 0o664) { |f| f.write(contents) }
      end

      def random_file_name(tmp: RELATIVE_TMP)
        Pathname.new(tmp).join(random_string, "#{random_string}.log")
      end

      def file_with_directory(tmp: RELATIVE_TMP)
        random_file_name(tmp: tmp).tap do |result|
          mkdir_p(result)
        end
      end

      def mkdir_p(destination)
        Pathname.new(destination).dirname.mkpath
      end

      def random_string(length: 16)
        SecureRandom.alphanumeric(length)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files
end
