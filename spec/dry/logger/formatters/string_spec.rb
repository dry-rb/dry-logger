# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::String do
  subject(:logger) do
    Dry.Logger(:test, template: "[%<progname>s] [%<severity>s] [%<time>s] %<message>s")
  end

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  describe "using customized template" do
    it "when passed as a symbol, it has key=value format for string messages" do
      output = with_captured_stdout do
        logger.info("foo")
      end

      expect(output).to eq "[test] [INFO] [2017-01-15 16:00:23 +0100] foo\n"
    end

    it "has key=value format for hash messages" do
      output = with_captured_stdout do
        logger.info(foo: "bar")
      end

      expect(output).to eq %([test] [INFO] [2017-01-15 16:00:23 +0100] foo="bar"\n)
    end

    it "has key=value format for error messages" do
      backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

      output = with_captured_stdout do
        logger.error(exception)
      end

      expected = <<~STR
        [test] [ERROR] [2017-01-15 16:00:23 +0100] StandardError: foo
        from file-1.rb:312
        from file-2.rb:12
        from file-3.rb:115
        STR

      expect(output).to eql(expected)
    end
  end
end
