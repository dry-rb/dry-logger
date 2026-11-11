# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::Structured do
  subject(:formatter) { formatter_class.new }

  let(:formatter_class) do
    Class.new(described_class) do
      private

      def format_severity(value) = value.upcase

      def format_secret(_value) = "[hidden]"
    end
  end

  def entry(**payload)
    Dry::Logger::Entry.new(
      clock: Dry::Logger::Clock.new, progname: "test", severity: "info", payload: payload
    )
  end

  describe "#format_values" do
    it "formats values with a matching format method, including private ones" do
      result = formatter.format_values(entry(secret: "abc", other: "def"))

      expect(result).to include(severity: "INFO", secret: "[hidden]", other: "def")
    end

    it "formats the same way for every entry" do
      3.times do |i|
        result = formatter.format_values(entry(secret: i, other: i))

        expect(result).to include(severity: "INFO", secret: "[hidden]", other: i)
      end
    end

    it "keeps formatting keys with and without a format method after seeing many distinct keys" do
      1_000.times { |i| formatter.format_values(entry("key_#{i}": i)) }

      result = formatter.format_values(entry(secret: "abc", key_999: 1, brand_new: 2))

      expect(result).to include(secret: "[hidden]", key_999: 1, brand_new: 2)
    end

    it "does not share format methods between formatter classes" do
      formatter.format_values(entry(secret: "abc"))

      expect(described_class.new.format_values(entry(secret: "abc"))).to include(secret: "abc")
    end
  end
end
