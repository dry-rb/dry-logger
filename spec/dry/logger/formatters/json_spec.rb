# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::JSON do
  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  it "when passed as a symbol, it has JSON format for string messages" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: :json).info("foo")
    end

    expected_json = {
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo"
    }

    expect(output).to eql("#{JSON.dump(expected_json)}\n")
    expect(JSON.parse(output)).to eql(expected_json)
  end

  it "has JSON format for string messages" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info("foo")
    end

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo"
    )
  end

  it "has JSON format for string messages with payloads" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info("foo", test: true)
    end

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo",
      "test" => true
    )
  end

  it "has JSON format for error messages" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).error(Exception.new("foo"))
    end

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "ERROR",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo",
      "backtrace" => [],
      "error" => "Exception"
    )
  end

  it "has JSON format for hash messages" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info(foo: :bar)
    end

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "foo" => "bar"
    )
  end

  it "has JSON format for not string messages" do
    output = with_captured_stdout do
      Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info(["foo"])
    end

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => ["foo"]
    )
  end
end
