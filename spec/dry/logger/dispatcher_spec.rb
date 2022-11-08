# frozen_string_literal: true

require "dry/logger/dispatcher"

RSpec.describe Dry::Logger::Dispatcher do
  include_context "stream"

  Dry::Logger::LEVELS.each_key do |level|
    describe "##{level}" do
      subject(:logger) { Dry.Logger(:test, stream: stream, level: level) }

      it "logs a text message with a corresponding severity" do
        message = "Hello World!"

        logger.public_send(level, message)

        expect(stream).to include(message)
      end
    end
  end

  describe "#add_backend" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    it "adds a new backend" do
      logger.add_backend(stream: SPEC_ROOT.join("../log/test.log"))

      expect(logger.backends.size).to be(2)
      expect(logger.backends.last).to be_instance_of(Dry::Logger::Backends::File)
    end

    it "adds a new backend with conditional dispatch" do
      logger
        .add_backend(formatter: :string, template: "first: %<message>s") { |backend|
          backend.log_if = -> entry { entry.info? }
        }
        .add_backend(formatter: :string, template: "second: %<message>s")

      logger.info("hello")
      logger.warn("world")

      expect(stream).to include("first: hello")
      expect(stream).to_not include("first: world")

      expect(stream).to include("second: world")
    end

    it "works with a stdlib logger" do
      logger.add_backend(Logger.new(stream))

      logger.info "Hello World"

      expect(stream).to include("Hello World")
    end
  end

  describe "#log" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    it "logs and returns true" do
      expect(logger.info("Hello World")).to be(true)
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

  describe "#tagged" do
    subject(:logger) { Dry.Logger(:test, stream: stream, template: "%<message>s", context: {}) }

    it "sets tags in log entries" do
      logger.tagged(:metrics) do
        logger.info("test 1")
        logger.info("test 2")
      end

      expect(stream).to include("test 1 tag=:metrics")
      expect(stream).to include("test 2 tag=:metrics")
    end
  end

  describe "#context" do
    subject(:logger) { Dry.Logger(:test, stream: stream, template: "%<message>s", context: {}) }

    it "allows set pre-defined payload data" do
      logger.context[:component] = "test"

      logger.info("test 1")
      logger.info("test 2")

      expect(stream).to include('test 1 component="test"')
      expect(stream).to include('test 2 component="test"')
    end
  end
end
