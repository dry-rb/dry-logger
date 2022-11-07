# frozen_string_literal: true

require "dry/logger/dispatcher"

RSpec.describe Dry::Logger::Dispatcher do
  describe "#add_backend" do
    subject(:logger) { Dry.Logger(:test) }

    it "adds a new backend" do
      logger.add_backend(stream: SPEC_ROOT.join("../log/test.log"))

      expect(logger.backends.size).to be(2)
      expect(logger.backends.last).to be_instance_of(Dry::Logger::Backends::File)
    end
  end

  describe "#close" do
    subject(:logger) { Dry.Logger(:test) }

    let(:backend_one) { instance_spy(Dry::Logger::Backends::Stream) }
    let(:backend_two) { instance_spy(Dry::Logger::Backends::Stream) }

    before do
      logger.add_backend(backend_one).add_backend(backend_two)
    end

    it "closes all backends" do
      expect(logger.close).to be(true)

      expect(backend_one).to have_received(:close)
      expect(backend_two).to have_received(:close)
    end
  end
end
