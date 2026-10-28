# frozen_string_literal: true

module Dry
  module Logger
    # Log filtering logic.
    #
    # Filters match keys as follows:
    #
    # - A string or symbol matches any key where the text appears in the key or its full dotted
    #   path. For example, `"password"` matches `password`, `password_confirmation` and
    #   `user.new_password`, and `"user.token"` matches `user.token`, `user.token_type` and
    #   `admin.user.token`, but not a top-level `token`.
    # - A regexp matches any key where the regexp matches the key or its full dotted path. For
    #   example, `/\Apin\z/` matches `pin` and `user.pin`, and `/\Acard\.number\z/` matches
    #   `card.number`, but not `payment.card.number`.
    #
    # String and symbol filters ignore case. Regexp filters are case-sensitive unless they use the
    # `i` flag, such as `/\Apin\z/i`.
    #
    # Whitespace is stripped from the start and end of string and symbol filters. Fully blank
    # filters are ignored with a warning, since they would match every key.
    #
    # When a key matches and its value is a hash or an array, every value inside it is filtered.
    #
    # Hashes inside arrays are also filtered. Their keys use the array's key in their dotted path,
    # with no index. For example, `"users.password"` matches `{users: [{password: "secret"}]}`.
    #
    # @api private
    class Filter
      FILTERED = "[FILTERED]"
      private_constant :FILTERED

      PATH_SEPARATOR = "."
      private_constant :PATH_SEPARATOR

      private attr_reader :matcher

      def initialize(filters = [])
        @matcher = build_matcher(reject_blank_filters(strip_filters(filters)))
      end

      def call(hash)
        _filter_hash(hash)
      end

      private

      # Strips whitespace from string filters.
      def strip_filters(filters)
        filters.map { |filter| filter.is_a?(Regexp) ? filter : filter.to_s.strip }
      end

      def reject_blank_filters(filters)
        blank, present = filters.partition { |filter| filter.to_s.empty? }

        unless blank.empty?
          warn "dry-logger: ignoring blank log filter(s). Blank filters would match every key."
        end

        present
      end

      # Returns a regexp matching any of the filters. With no filters, it matches nothing.
      def build_matcher(filters)
        Regexp.union(
          filters.map { |filter|
            filter.is_a?(Regexp) ? filter : /#{Regexp.escape(filter.to_s)}/i
          }
        )
      end

      # Returns a filtered copy of the hash, leaving the original unchanged.
      def _filter_hash(hash, parent_path = nil)
        hash.each_with_object({}) do |(key, value), result|
          path = parent_path ? "#{parent_path}#{PATH_SEPARATOR}#{key}" : key.to_s

          result[key] =
            if _filter?(key.to_s, path)
              _filtered_value(value)
            else
              _filter_value(value, path)
            end
        end
      end

      def _filter_value(value, path)
        case value
        when Hash
          _filter_hash(value, path)
        when Array
          value.map { |item| _filter_value(item, path) }
        else
          value
        end
      end

      # Returns true if any filter matches the key or its full dotted path.
      def _filter?(key, path)
        # Checking the key catches anchored regexps such as `/\Apin\z/` on nested keys. Checking the
        # path catches filters that span keys, such as `"user.token"`.
        matcher.match?(key) || matcher.match?(path)
      end

      # Filters every value inside a hash or array, keeping hash keys and array lengths so the
      # shape of the data is still visible in the logs.
      def _filtered_value(value)
        case value
        when Hash
          value.transform_values { |nested| _filtered_value(nested) }
        when Array
          value.map { |item| _filtered_value(item) }
        else
          FILTERED
        end
      end
    end
  end
end
