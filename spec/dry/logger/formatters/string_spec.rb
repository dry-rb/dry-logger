# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::String do
  include_context "stream"

  subject(:logger) do
    Dry.Logger(:test, stream: stream, formatter: formatter, template: template)
  end

  let(:formatter) do
    described_class
  end

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  describe "using customized template with `message` token" do
    let(:template) do
      "[%<progname>s] [%<severity>s] [%<time>s] %<message>s"
    end

    it "when passed as a symbol, it has key=value format for string messages" do
      logger.info("foo")

      expect(output).to eq "[test] [INFO] [2017-01-15 16:00:23 +0100] foo\n"
    end

    it "has key=value format for hash messages" do
      logger.info(foo: "bar")

      expect(output).to eq %([test] [INFO] [2017-01-15 16:00:23 +0100] foo="bar"\n)
    end

    it "has key=value format for error messages" do
      backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

      logger.error(exception)

      expected = <<~STR
        [test] [ERROR] [2017-01-15 16:00:23 +0100] foo exception=StandardError \
        backtrace=#{backtrace.inspect}
      STR

      expect(output).to eql(expected)
    end
  end

  describe "using customized template with payload keys as tokens" do
    let(:template) do
      "[%<severity>s] %<verb>s %<path>s"
    end

    it "replaces tokens with payload values" do
      logger.info verb: "POST", path: "/users"

      expect(output).to eql("[INFO] POST /users\n")
    end

    it "replaces tokens with payload values and dumps payload's remainder" do
      logger.info verb: "POST", path: "/users", foo: "bar"

      expect(output).to eql(%([INFO] POST /users foo="bar"\n))
    end
  end

  describe "using customized formatter" do
    let(:formatter) do
      Class.new(described_class) do
        def format_verb(value)
          "VERB:#{value}"
        end
      end
    end

    let(:template) do
      "[%<severity>s] %<verb>s %<path>s"
    end

    it "replaces tokens with payload values using custom formatting methods" do
      logger.info verb: "POST", path: "/users"

      expect(output).to eql("[INFO] VERB:POST /users\n")
    end

    it "replaces tokens with payload values and dumps payload's remainder" do
      logger.info verb: "POST", path: "/users", foo: "bar"

      expect(output).to eql(%([INFO] VERB:POST /users foo="bar"\n))
    end
  end
end
