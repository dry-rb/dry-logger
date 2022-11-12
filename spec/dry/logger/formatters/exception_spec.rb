# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::Exception do
  include_context "stream"

  subject(:logger) do
    Dry.Logger(:test, stream: stream, formatter: :exception)
  end

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  it "logs exception information and a backtrace" do
    backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
    exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

    logger.error(exception)

    expected = <<~STR
      [test] [ERROR] [2017-01-15 16:00:23 +0100] exception=StandardError message="foo"
        file-1.rb:312
        file-2.rb:12
        file-3.rb:115
    STR

    expect(output).to eql(expected)
  end
end
