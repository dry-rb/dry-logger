# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::JSON do
  include_context "stream"

  subject(:logger) do
    Dry.Logger(:test, stream: stream, formatter: :json)
  end

  it "when passed as a symbol, it has JSON format for string messages" do
    logger.info("foo")

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
    logger.info("foo")

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo"
    )
  end

  it "has JSON format for string messages with payloads" do
    logger.info("foo", test: true)

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo",
      "test" => true
    )
  end

  it "has JSON format for error messages" do
    logger.error(Exception.new("foo"))

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "ERROR",
      "time" => "2017-01-15T15:00:23Z",
      "message" => "foo",
      "backtrace" => [],
      "exception" => "Exception"
    )
  end

  it "has JSON format for hash messages" do
    logger.info(foo: :bar)

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "foo" => "bar"
    )
  end

  it "has JSON format for not string messages" do
    logger.info(["foo"])

    expect(JSON.parse(output)).to eql(
      "progname" => "test",
      "severity" => "INFO",
      "time" => "2017-01-15T15:00:23Z",
      "message" => ["foo"]
    )
  end
end
