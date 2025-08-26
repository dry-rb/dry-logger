# frozen_string_literal: true

module RSpec
  module Support
    # Hash#to_s was changed in Ruby 3.4.0
    module HashString
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0")
        refine ::Hash do
          def to_s
            map { |key, value| "#{key.inspect}=>#{value.inspect}" }.then do |pairs|
              "{#{pairs.join(",")}}"
            end
          end
        end
      end
    end
  end
end
