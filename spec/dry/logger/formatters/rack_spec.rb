# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::Rack do
  include_context "stream"

  subject(:logger) do
    Dry.Logger(:test, stream: stream, formatter: :rack, filters: filters)
  end

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  let(:filters) do
    %w[password password_confirmation credit_card user.login]
  end

  let(:params) do
    {
      "password" => "password",
      "password_confirmation" => "password",
      "credit_card" => {
        "number" => "4545 4545 4545 4545",
        "name" => "John Citizen"
      },
      "user" => {
        "login" => "John",
        "name" => "John"
      }
    }
  end

  let(:payload) do
    {verb: "POST",
     status: 200,
     elapsed: "2ms",
     ip: "127.0.0.1",
     path: "/api/users",
     length: 312,
     params: params}
  end

  let(:filtered_params) do
    {"password" => "[FILTERED]",
    "password_confirmation" => "[FILTERED]",
    "credit_card" => {
      "number" => "[FILTERED]",
      "name" => "[FILTERED]"
    },
    "user" => {
      "login" => "[FILTERED]",
      "name" => "John"
    }}
  end

  context "with filters" do
    it "filters values for keys in the filters array" do
      logger.info(payload)

      expect(output).to eql(<<~LOG.strip)
        [test] [INFO] [2017-01-15 16:00:23 +0100] POST 200 2ms 127.0.0.1 /api/users 312 \
        #{filtered_params}
      LOG
    end
  end

  context "with an exception" do
    it "logs exception details with a backtrace and additional payload" do
      backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

      logger.error(exception, **payload)

      expected = <<~LOG.strip
        [test] [ERROR] [2017-01-15 16:00:23 +0100] POST 200 2ms 127.0.0.1 /api/users 312 \
        #{filtered_params} \
        exception=StandardError message="foo" \
        backtrace=["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      LOG

      expect(output).to eql(expected)
    end
  end
end
