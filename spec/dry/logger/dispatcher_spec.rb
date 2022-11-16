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

    describe "##{level} when a custom backend crashes" do
      subject(:logger) do
        Dry.Logger(:test, stream: stream, level: level) do |setup|
          setup.add_backend { |backend| backend.log_if = -> _ { raise(exception) } }
        end
      end

      let(:exception) do
        StandardError.new("Oops").tap { |e| e.set_backtrace(["file-1.rb:12", "file-2.rb:41"]) }
      end

      it "uses on_crash callback" do
        # message = <<~LOG
        #   [test] [FATAL] [2017-01-15 16:00:23 +0100] Logging crashed
        #     Hello World!
        #     Oops (StandardError)
        #     file-1.rb:12
        #     file-2.rb:41
        # LOG
        #
        # TODO: for some reason output matcher doesn't work here
        # .     so this is going to spit things out in the test output
        expect { logger.public_send(level, "Hello World!") }.to_not raise_error
      end
    end

    describe "##{level} when dispatching crashes" do
      subject(:logger) do
        Dry.Logger(:test, stream: stream, level: level)
      end

      let(:exception) do
        StandardError.new("Oops").tap { |e| e.set_backtrace(["file-1.rb:12", "file-2.rb:41"]) }
      end

      it "uses on_crash callback" do
        # message = <<~LOG
        #   [test] [FATAL] [2017-01-15 16:00:23 +0100] Logging crashed
        #     Hello World!
        #     Oops (StandardError)
        #     file-1.rb:12
        #     file-2.rb:41
        # LOG
        #
        # TODO: for some reason output matcher doesn't work here
        # .     so this is going to spit things out in the test output

        allow(Dry::Logger::Entry).to receive(:new).and_raise(exception)

        expect { logger.public_send(level, "Hello World!") }.to_not raise_error
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

    it "works with a any compatible object and supports conditional logging" do
      other_logger = Logger.new(stream)

      logger.add_backend(other_logger) { |backend| backend.log_if = :error?.to_proc }

      other_logger.formatter = -> (_, _, _, msg) { "from other: #{msg}" }

      logger.info "Hello World"
      logger.error "Oops"

      expect(stream).to_not include("from other: Hello World")
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
    context "when template doesn't include tags" do
      subject(:logger) do
        Dry.Logger(:test, stream: stream, context: {}) { |setup|
          setup.add_backend do |backend|
            backend.log_if = -> entry { !entry.tag?(:rack) }
          end

          setup.add_backend(template: "request: %<verb>s %<path>s") do |backend|
            backend.log_if = -> entry { entry.tag?(:rack) }
          end
        }
      end

      it "allows filterring by tags but doesn't include them in log entries" do
        logger.info("Hello World")

        logger.tagged(:rack) do
          logger.info(verb: "GET", path: "/users")
        end

        expect(stream.string).to include("Hello World\n")
        expect(stream.string).to include("request: GET /users\n")
      end
    end

    context "when template include tags" do
      subject(:logger) do
        Dry.Logger(
          :test,
          stream: stream, template: "[%<tags>s] %<message>s %<payload>s", context: {}
        )
      end

      it "includes tags as symbols in log entries" do
        logger.tagged(:metrics) do
          logger.info("test 1")
          logger.info("test 2")
        end

        expect(stream).to include("[metrics] test 1")
        expect(stream).to include("[metrics] test 2")
      end

      it "includes tags as hashes in log entries" do
        logger.tagged(metrics: true) do
          logger.info("test 1")
          logger.info("test 2")
        end

        expect(stream).to include("[metrics=true] test 1")
        expect(stream).to include("[metrics=true] test 2")
      end

      it "includes tags as symbols and hashes in log entries" do
        logger.tagged(:analytics, metrics: true) do
          logger.info("test 1")
          logger.info("test 2")
        end

        expect(stream).to include("[analytics metrics=true] test 1")
        expect(stream).to include("[analytics metrics=true] test 2")
      end
    end
  end

  describe "#context" do
    subject(:logger) do
      Dry.Logger(:test, stream: stream, template: "%<message>s %<payload>s", context: {})
    end

    it "allows set pre-defined payload data" do
      logger.context[:component] = "test"

      logger.info("test 1")
      logger.info("test 2")

      expect(stream).to include('test 1 component="test"')
      expect(stream).to include('test 2 component="test"')
    end
  end
end
