# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::String do
  include_context "stream"

  subject(:logger) do
    Dry.Logger(:test, stream: stream, formatter: formatter, template: template, **options)
  end

  let(:formatter) do
    described_class
  end

  let(:options) do
    {}
  end

  describe "using :default template" do
    let(:template) do
      :default
    end

    it "logs message" do
      logger.info "Hello World"
      expect(output).to eql("Hello World\n")
    end

    it "logs payload" do
      logger.info text: "Hello World"
      expect(output).to eql(%[text="Hello World"\n])
    end

    it "logs message and payload" do
      logger.info "Hello World", more: "data"
      expect(output).to eql(%[Hello World more="data"\n])
    end
  end

  describe "using :details template" do
    let(:template) do
      :details
    end

    it "logs message" do
      logger.info "Hello World"
      expect(output).to eql("[test] [INFO] [2017-01-15 16:00:23 +0100] Hello World\n")
    end

    it "logs payload" do
      logger.info text: "Hello World"
      expect(output).to eql(%[[test] [INFO] [2017-01-15 16:00:23 +0100] text="Hello World"\n])
    end

    it "logs message and payload" do
      logger.info "Hello World", more: "data"
      expect(output).to eql(%[[test] [INFO] [2017-01-15 16:00:23 +0100] Hello World more="data"\n])
    end
  end

  describe "using customized template with `message` token" do
    let(:template) do
      "[%<progname>s] [%<severity>s] [%<time>s] [message:%<message>s] %<payload>s"
    end

    it "when passed as a symbol, it has key=value format for string messages" do
      logger.info("foo")

      expect(output).to eq "[test] [INFO] [2017-01-15 16:00:23 +0100] [message:foo]\n"
    end

    it "has key=value format for hash messages" do
      logger.info(foo: "bar")

      expect(output).to eq %([test] [INFO] [2017-01-15 16:00:23 +0100] [message:foo="bar"]\n)
    end

    it "has key=value format for error messages" do
      backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

      logger.error(exception)

      expected = <<~STR
        [test] [ERROR] [2017-01-15 16:00:23 +0100] [message:]
          foo (StandardError)
          file-1.rb:312
          file-2.rb:12
          file-3.rb:115
      STR

      expect(output).to eql(expected)
    end
  end

  describe "using customized template with payload keys as tokens" do
    let(:template) do
      "[%<severity>s] %<verb>s %<path>s %<payload>s"
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

  describe "using colorized template" do
    let(:template) do
      "[%<severity>s] <green>%<verb>s</green> <cyan>%<path>s</cyan>"
    end

    it "replaces tokens with colorized payload values" do
      logger.info verb: "POST", path: "/users"

      expect(output).to eql("[INFO] \e[32mPOST\e[0m \e[36m/users\e[0m\n")
    end
  end

  describe "using colorized mode" do
    let(:template) do
      "[%<severity>s] %<message>s"
    end

    context "with default severity colors" do
      let(:options) do
        {colorize: true}
      end

      it "colorizes severity" do
        logger.info "Hello World"

        expect(output).to eql("[\e[35mINFO\e[0m] Hello World\n")
      end
    end

    context "with customized severity colors" do
      let(:options) do
        {colorize: true, severity_colors: {info: :blue}}
      end

      it "colorizes severity using custom color" do
        logger.info "Hello World"

        expect(output).to eql("[\e[34mINFO\e[0m] Hello World\n")
      end
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
      "[%<severity>s] %<verb>s %<path>s %<payload>s"
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
