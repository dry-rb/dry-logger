# frozen_string_literal: true

require "date"

RSpec.describe "Dry.Logger" do
  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  it "raises on unsupported stream type" do
    expect { Dry.Logger(:test, stream: []) }.to raise_error(ArgumentError, /unsupported/)
  end

  context "default" do
    subject(:logger) { Dry.Logger(:test) }

    it "uses $stdout by default" do
      message = "hello, world"

      output = with_captured_stdout do
        logger.info(message)
      end

      expect(output).to match(message)
    end
  end

  context "file" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    context "relative path" do
      let(:stream) { random_file_name }

      context "when file doesn't exist" do
        it "creates file" do
          logger
          expect(stream).to be_exist

          logger.info(message = "newline")
          expect(read(stream)).to match(message)
        end
      end

      context "when file already exists" do
        before do
          generate_file(stream, existing_message)
        end

        let(:existing_message) { "existing" }

        it "appends to file" do
          logger.info(new_message = "appended")

          expect(read(stream)).to match(existing_message)
          expect(read(stream)).to match(new_message)
        end
      end
    end

    context "absolute path" do
      let(:stream) { random_file_name(tmp: TMP) }

      it "creates file" do
        logger
        expect(stream).to be_exist
      end
    end
  end

  context "when IO" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    let(:stream) { io_stream(destination) }
    let(:destination) { file_with_directory }

    it "appends" do
      logger.info(message = "foo")
      logger.close

      expect(read(destination)).to match(message)
    end
  end

  context "when StringIO" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    let(:stream) { StringIO.new }

    it "appends" do
      logger.info(message = "foo")

      expect(read(stream)).to match(message)
    end
  end

  context "log level" do
    subject(:logger) { Dry.Logger(:test, level: level) }

    it "uses INFO by default" do
      expect(Dry.Logger(:test).level).to eq(Dry::Logger::INFO)
    end

    context "when integer" do
      let(:level) { 3 }

      it "translates into level" do
        expect(logger.level).to eq(Dry::Logger::ERROR)
      end
    end

    context "when integer out of boundary" do
      let(:level) { 99 }

      it "sets level to default" do
        expect(logger.level).to eq(Dry::Logger::INFO)
      end
    end

    context "when symbol" do
      let(:level) { :error }

      it "translates into level" do
        expect(logger.level).to eq(Dry::Logger::ERROR)
      end
    end

    context "when string" do
      let(:level) { "error" }

      it "translates into level" do
        expect(logger.level).to eq(Dry::Logger::ERROR)
      end
    end

    context "when uppercased string" do
      let(:level) { "ERROR" }

      it "translates into level" do
        expect(logger.level).to eq(Dry::Logger::ERROR)
      end
    end

    context "when unknown level" do
      let(:level) { "foo" }

      it "sets level to default" do
        expect(logger.level).to eq(Dry::Logger::INFO)
      end
    end

    context "when constant" do
      let(:level) { Dry::Logger::ERROR }

      it "translates into level" do
        expect(logger.level).to eq(Dry::Logger::ERROR)
      end
    end
  end

  describe "with nil formatter" do
    subject(:logger) { Dry.Logger(:test, formatter: nil) }

    it "falls back to Formatter" do
      output = with_captured_stdout do
        logger.info("foo")
      end

      expect(output).to eq "foo\n"
    end
  end

  describe "with JSON formatter" do
    it "when passed as a symbol, it has JSON format for string messages" do
      output = with_captured_stdout do
        Dry.Logger(:test, formatter: :json).info("foo")
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":"foo"}\n)
    end

    it "has JSON format for string messages" do
      output = with_captured_stdout do
        Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info("foo")
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":"foo"}\n)
    end

    it "has JSON format for error messages" do
      output = with_captured_stdout do
        Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).error(Exception.new("foo"))
      end

      expect(output).to eq %({"severity":"ERROR","time":"2017-01-15T15:00:23Z","message":"foo","backtrace":[],"error":"Exception"}\n)
    end

    it "has JSON format for hash messages" do
      output = with_captured_stdout do
        Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info(foo: :bar)
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","foo":"bar"}\n)
    end

    it "has JSON format for not string messages" do
      output = with_captured_stdout do
        Dry.Logger(:test, formatter: Dry::Logger::Formatters::JSON.new).info(["foo"])
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":["foo"]}\n)
    end
  end

  describe "with application formatter" do
    subject(:logger) { Dry.Logger(:test, formatter: :application) }

    it "when passed as a symbol, it has key=value format for string messages" do
      output = with_captured_stdout do
        logger.info("foo")
      end

      expect(output).to eq "[INFO] [2017-01-15 16:00:23 +0100] foo\n"
    end

    it "has key=value format for hash messages" do
      output = with_captured_stdout do
        logger.info(foo: "bar")
      end

      expect(output).to eq %([INFO] [2017-01-15 16:00:23 +0100] foo="bar"\n)
    end

    it "has key=value format for error messages" do
      exc = nil
      output = with_captured_stdout do
        begin
          raise StandardError, "foo"
        rescue StandardError => e
          exc = e
        end
        logger.error(exc)
      end

      expectation = "[ERROR] [2017-01-15 16:00:23 +0100] StandardError: foo\n"
      backtrace = exc.backtrace.map { |line| "from #{line}\n" }.join

      expect(output).to eq(expectation + backtrace)
    end
  end

  describe "with filters" do
    let(:filters) { %w[password password_confirmation credit_card user.login] }

    let(:params) do
      Hash[
        params: Hash[
          "password" => "password",
          "password_confirmation" => "password",
          "credit_card" => Hash[
            "number" => "4545 4545 4545 4545",
            "name" => "John Citizen"
          ],
          "user" => Hash[
            "login" => "John",
            "name" => "John"
          ]
        ]
      ]
    end

    subject(:logger) { Dry.Logger(:test, formatter: :application, filters: filters) }

    it "filters values for keys in the filters array" do
      expected = %s({"password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]", "credit_card"=>{"number"=>"[FILTERED]", "name"=>"[FILTERED]"}, "user"=>{"login"=>"[FILTERED]", "name"=>"John"}})

      output = with_captured_stdout do
        logger.info(params)
      end

      expect(output).to eq("[INFO] [2017-01-15 16:00:23 +0100] #{expected}\n")
    end
  end

  describe "#close" do
    before do
      logger.close
    end

    subject(:logger) { Dry.Logger(:test, stream: stream) }

    context "when stream is $stdout" do
      let(:stream) { $stdout }

      it "does not close stream" do
        expect { print "in $stdout" }.to output("in $stdout").to_stdout
      end
    end

    context "when stream is STDOUT" do
      let(:stream) { STDOUT }

      it "does not close stream" do
        expect { print "in STDOUT" }.to output("in STDOUT").to_stdout
      end
    end

    context "when file" do
      let(:stream) { random_file_name }

      it "closes stream" do
        logger.info(message = "foo")

        expect(read(stream)).to_not match(message)
      end
    end

    context "when StringIO" do
      let(:stream) { StringIO.new }

      it "closes stream" do
        logger.info("foo")

        expect { read(stream) }.to raise_error(IOError)
      end
    end

    context "when IO" do
      let(:stream) { io_stream(destination) }
      let(:destination) { file_with_directory }

      it "closes stream" do
        logger.info(message = "foo")
        logger.close

        expect(read(destination)).to_not match(message)
      end
    end
  end
end
