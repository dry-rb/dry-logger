# frozen_string_literal: true

require "date"

RSpec.describe Dry::Logger do
  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  describe ".new" do
    subject { described_class.new }

    it "returns a frozen instance of a stream logger" do
      expect(subject).to be_kind_of(Dry::Logger::Stream)
      expect(subject).to be_frozen
    end

    context "stream" do
      it "uses $stdout by default" do
        message = "hello, world"
        output = with_captured_stdout do
          subject.info(message)
        end

        expect(output).to match(message)
      end

      context "file" do
        subject { described_class.new(stream: stream) }

        context "relative path" do
          let(:stream) { random_file_name }

          context "when file doesn't exist" do
            it "creates file" do
              subject
              expect(stream).to be_exist

              subject.info(message = "newline")
              expect(read(stream)).to match(message)
            end
          end

          context "when file already exists" do
            before do
              generate_file(stream, existing_message)
            end

            let(:existing_message) { "existing" }

            it "appends to file" do
              subject.info(new_message = "appended")

              expect(read(stream)).to match(existing_message)
              expect(read(stream)).to match(new_message)
            end
          end
        end

        context "absolute path" do
          let(:stream) { random_file_name(tmp: TMP) }

          it "creates file" do
            subject
            expect(stream).to be_exist
          end
        end
      end

      context "when IO" do
        subject { described_class.new(stream: stream) }

        let(:stream) { io_stream(destination) }
        let(:destination) { file_with_directory }

        it "appends" do
          subject.info(message = "foo")
          subject.close

          expect(read(destination)).to match(message)
        end
      end

      context "when StringIO" do
        subject { described_class.new(stream: stream) }
        let(:stream) { StringIO.new }

        it "appends" do
          subject.info(message = "foo")

          expect(read(stream)).to match(message)
        end
      end
    end

    context "log level" do
      subject { described_class.new(level: level) }

      it "uses INFO by default" do
        expect(described_class.new.level).to eq(Dry::Logger::INFO)
      end

      context "when integer" do
        let(:level) { 3 }

        it "translates into level" do
          expect(subject.level).to eq(Dry::Logger::ERROR)
        end
      end

      context "when integer out of boundary" do
        let(:level) { 99 }

        it "sets level to default" do
          expect(subject.level).to eq(Dry::Logger::INFO)
        end
      end

      context "when symbol" do
        let(:level) { :error }

        it "translates into level" do
          expect(subject.level).to eq(Dry::Logger::ERROR)
        end
      end

      context "when string" do
        let(:level) { "error" }

        it "translates into level" do
          expect(subject.level).to eq(Dry::Logger::ERROR)
        end
      end

      context "when uppercased string" do
        let(:level) { "ERROR" }

        it "translates into level" do
          expect(subject.level).to eq(Dry::Logger::ERROR)
        end
      end

      context "when unknown level" do
        let(:level) { "foo" }

        it "sets level to default" do
          expect(subject.level).to eq(Dry::Logger::INFO)
        end
      end

      context "when constant" do
        let(:level) { Dry::Logger::ERROR }

        it "translates into level" do
          expect(subject.level).to eq(Dry::Logger::ERROR)
        end
      end
    end
  end

  describe "with nil formatter" do
    subject { described_class.new(formatter: nil) }

    it "falls back to Formatter" do
      output = with_captured_stdout do
        subject.info("foo")
      end

      expect(output).to eq "foo\n"
    end
  end

  describe "with JSON formatter" do
    it "when passed as a symbol, it has JSON format for string messages" do
      output = with_captured_stdout do
        described_class.new(formatter: :json).info("foo")
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":"foo"}\n)
    end

    it "has JSON format for string messages" do
      output = with_captured_stdout do
        described_class.new(formatter: Dry::Logger::JSONFormatter.new).info("foo")
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":"foo"}\n)
    end

    it "has JSON format for error messages" do
      output = with_captured_stdout do
        described_class.new(formatter: Dry::Logger::JSONFormatter.new).error(Exception.new("foo"))
      end

      expect(output).to eq %({"severity":"ERROR","time":"2017-01-15T15:00:23Z","message":"foo","backtrace":[],"error":"Exception"}\n)
    end

    it "has JSON format for hash messages" do
      output = with_captured_stdout do
        described_class.new(formatter: Dry::Logger::JSONFormatter.new).info(foo: :bar)
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","foo":"bar"}\n)
    end

    it "has JSON format for not string messages" do
      output = with_captured_stdout do
        described_class.new(formatter: Dry::Logger::JSONFormatter.new).info(["foo"])
      end

      expect(output).to eq %({"severity":"INFO","time":"2017-01-15T15:00:23Z","message":["foo"]}\n)
    end
  end

  describe "with application formatter" do
    subject { described_class.new(formatter: :application) }

    it "when passed as a symbol, it has key=value format for string messages" do
      output = with_captured_stdout do
        subject.info("foo")
      end

      expect(output).to eq "[INFO] [2017-01-15 16:00:23 +0100] foo\n"
    end

    it "has key=value format for hash messages" do
      output = with_captured_stdout do
        subject.info(foo: "bar")
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
        subject.error(exc)
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

    subject { described_class.new(formatter: :application, filters: filters) }

    it "filters values for keys in the filters array" do
      expected = %s({"password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]", "credit_card"=>{"number"=>"[FILTERED]", "name"=>"[FILTERED]"}, "user"=>{"login"=>"[FILTERED]", "name"=>"John"}})

      output = with_captured_stdout do
        subject.info(params)
      end

      expect(output).to eq("[INFO] [2017-01-15 16:00:23 +0100] #{expected}\n")
    end
  end

  describe "#close" do
    before do
      subject.close
    end

    subject { described_class.new(stream: stream) }

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
        subject.info(message = "foo")

        expect(read(stream)).to_not match(message)
      end
    end

    context "when StringIO" do
      let(:stream) { StringIO.new }

      it "closes stream" do
        subject.info("foo")

        expect { read(stream) }.to raise_error(IOError)
      end
    end

    context "when IO" do
      let(:stream) { io_stream(destination) }
      let(:destination) { file_with_directory }

      it "closes stream" do
        subject.info(message = "foo")
        subject.close

        expect(read(destination)).to_not match(message)
      end
    end
  end
end
