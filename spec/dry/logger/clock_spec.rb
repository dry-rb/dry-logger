# frozen_string_literal: true

RSpec.describe Dry::Logger::Clock do
  subject(:clock) do
    Dry::Logger::Clock.new
  end

  describe "#now" do
    it "returns current time in local timezone" do
      expect(clock.now.iso8601).to eql(Time.now.iso8601)
    end
  end

  describe "#measure" do
    it "measures execution time in nanosecond by default" do
      result, elapsed = clock.measure do
        sleep 0.12
        "it worked"
      end

      expect(result).to eql("it worked")
      expect(elapsed.to_s).to start_with("12")
      expect(elapsed.to_s.size).to be(9)
    end
  end
end
