# frozen_string_literal: true

RSpec.describe Dry::Logger::Backends::Proxy do
  include_context "stream"

  def test_backend(&block)
    Class.new {
      def initialize(stream)
        @stream = stream
      end

      class_eval(&block)
    }.new(stream)
  end

  it "forwards message" do
    backend = test_backend do
      def info(message)
        @stream.write(message)
      end
    end

    logger = Dry.Logger(:test) { |s| s.add_backend(backend) }

    message = "Hello World"

    logger.info(message)

    expect(output).to eql(message)
  end

  it "forwards message and payload" do
    backend = test_backend do
      def info(message, **payload)
        @stream.write("#{message} #{payload}")
      end
    end

    logger = Dry.Logger(:test) { |s| s.add_backend(backend) }

    logger.info("Hello World", test: true)

    expect(output).to eql("Hello World {:test=>true}")
  end

  it "forwards payload" do
    backend = test_backend do
      def info(**payload)
        @stream.write(payload)
      end
    end

    logger = Dry.Logger(:test) { |s| s.add_backend(backend) }

    logger.info(test: true)

    expect(output).to eql(%({:test=>true}))
  end

  it "forwards exceptions" do
    backend = test_backend do
      def error(exception)
        @stream.write(exception.message)
      end
    end

    logger = Dry.Logger(:test) { |s| s.add_backend(backend) }

    logger.error(StandardError.new("Oops"))

    expect(output).to eql("Oops")
  end

  it "forwards exceptions" do
    backend = test_backend do
      def error(exception, **payload)
        @stream.write("#{exception.message} #{payload}")
      end
    end

    logger = Dry.Logger(:test) { |s| s.add_backend(backend) }

    logger.error(StandardError.new("Oops"), test: true)

    expect(output).to eql("Oops {:test=>true}")
  end
end
