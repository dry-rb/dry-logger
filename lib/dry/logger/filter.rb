# frozen_string_literal: true

module Dry
  module Logger
    # Filtering logic
    # Originaly copied from hanami/utils (see Hanami::Logger)
    #
    # @api private
    class Filter
      # @api private
      def initialize(filters = [])
        @filters = filters
      end

      # @api private
      def call(hash)
        _filtered_keys(hash).each do |key|
          *keys, last = _actual_keys(hash, key.split("."))
          keys.inject(hash, :fetch)[last] = "[FILTERED]"
        end

        hash
      end

      private

      attr_reader :filters

      def _filtered_keys(hash)
        _key_paths(hash).select { |key|
          filters.any? { |filter|
            key =~ /(\.|\A)#{filter}(\.|\z)/
          }
        }
      end

      def _key_paths(hash, base = nil)
        hash.inject([]) do |results, (k, v)|
          results + (_key_paths?(v) ? _key_paths(v, _build_path(base, k)) : [_build_path(base, k)])
        end
      end

      def _build_path(base, key)
        [base, key.to_s].compact.join(".")
      end

      def _actual_keys(hash, keys)
        search_in = hash

        keys.inject([]) do |res, key|
          correct_key = search_in.key?(key.to_sym) ? key.to_sym : key
          search_in = search_in[correct_key]
          res + [correct_key]
        end
      end

      # Check if the given value can be iterated (`Enumerable`) and that isn't a `File`.
      # This is useful to detect closed `Tempfiles`.
      #
      # @see https://github.com/hanami/utils/pull/342
      def _key_paths?(value)
        value.is_a?(Enumerable) && !value.is_a?(File)
      end
    end
  end
end
