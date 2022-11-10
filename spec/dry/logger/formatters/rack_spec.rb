# frozen_string_literal: true

RSpec.describe Dry::Logger::Formatters::Rack do
  subject(:logger) do
    Dry.Logger(
      :test,
      formatter: :rack,
      template: "[%<progname>s] [%<severity>s] [%<time>s] %<message>s",
      filters: filters
    )
  end

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  let(:filters) do
    []
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
     params: params,
     time: Time.now}
  end

  context "with filters" do
    let(:filters) do
      %w[password password_confirmation credit_card user.login]
    end

    it "filters values for keys in the filters array" do
      expected = {
        "password" => "[FILTERED]",
        "password_confirmation" => "[FILTERED]",
        "credit_card" => {
          "number" => "[FILTERED]",
          "name" => "[FILTERED]"
        },
        "user" => {
          "login" => "[FILTERED]",
          "name" => "John"
        }
      }

      output = with_captured_stdout do
        logger.info(payload)
      end

      expect(output).to eq(<<~LOG)
        [test] [INFO] [2017-01-15 16:00:23 +0100] POST 200 2ms 127.0.0.1 /api/users 312 \
        2017-01-15 16:00:23 +0100 #{expected}
      LOG
    end
  end

  context "with an exception" do
    it "logs exception details with a backtrace" do
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

    it "logs exception details with a backtrace and additional payload" do
      backtrace = ["file-1.rb:312", "file-2.rb:12", "file-3.rb:115"]
      exception = StandardError.new("foo").tap { |e| e.set_backtrace(backtrace) }

      payload = {verb: "POST", status: 500, elapsed: "2ms", ip: "127.0.0.1", path: "/api/users"}

      output = with_captured_stdout do
        logger.error(exception, **payload)
      end

      expected = <<~STR
        [test] [ERROR] [2017-01-15 16:00:23 +0100] POST 500 2ms 127.0.0.1 /api/users StandardError: foo
        from file-1.rb:312
        from file-2.rb:12
        from file-3.rb:115
        STR

      expect(output).to eql(expected)
    end
  end
end
