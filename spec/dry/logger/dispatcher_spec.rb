# frozen_string_literal: true

require "dry/logger/dispatcher"

RSpec.describe Dry::Logger::Dispatcher do
  subject(:logger) { Dry.Logger(:test) }

  describe "#add_backend" do
    it "adds a new backend" do
      logger.add_backend(stream: SPEC_ROOT.join("../log/test.log"))

      expect(logger.backends.size).to be(2)
      expect(logger.backends.last).to be_instance_of(Dry::Logger::Backends::File)
    end
  end
end
