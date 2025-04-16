# frozen_string_literal: true

RSpec.describe Dry::Logger do
  include_context "stream"

  it "raises on unsupported stream type" do
    expect { Dry.Logger(:test, stream: []) }.to raise_error(ArgumentError, /unsupported/)
  end

  context "default" do
    subject(:logger) { Dry.Logger(:test, stream: stream) }

    it "logs to $stdout by default using a plain text message" do
      message = "hello, world"

      logger.info(message)

      expect(output).to match(message)
    end

    it "logs to $stdout by default using a plain text message and payload" do
      message = "hello, world"

      logger.info(message, test: true)

      expect(output).to match("#{message} test=true")
    end

    it "logs to $stdout by default using a plain text block message" do
      message = "hello, world"

      logger.info { message }

      expect(output).to match(message)
    end

    it "logs to $stdout by default using a plain text block message and payload" do
      message = "hello, world"

      logger.info(test: true) { message }

      expect(output).to match("#{message} test=true")
    end
  end

  context "using progname" do
    subject(:logger) { Dry.Logger(:test, stream: stream, template: "%<progname>s: %<message>s %<payload>s") }

    it "uses the logger ID as the progname" do
      message = "hello, world"

      logger.info(message)

      expect(output).to match("test: #{message}")
    end

    it "replaces the default progname with the progname: keyword argument" do
      message = "hello, world"

      logger.info(message, progname: "newprog", test: true)

      expect(output).to match("newprog: #{message} test=true")
    end

    it "replaces the progname with the first string argument when the message is given as a block" do
      message = "hello, world"

      logger.info("newprog") { message }

      expect(output).to match("newprog: hello, world")
    end

    it "replaces the progname with the progname: keyword argument when the message is given as a block" do
      message = "hello, world"

      logger.info(progname: "newprog", test: true) { message }

      expect(output).to match("newprog: #{message} test=true")
    end
  end

  context "adding backends via block only" do
    it "doesn't setup the default logger" do
      logger = Dry.Logger(:test, stream: stream) { |setup|
        setup.add_backend(formatter: :string, template: "[%<severity>s] %<message>s")
      }

      expect(logger.backends.size).to be(1)

      logger.info "Hello World!"

      expect(output).to eql("[INFO] Hello World!\n")
    end
  end

  context "registering a custom template" do
    subject(:logger) { Dry.Logger(:test, stream: stream, template: :my_details) }

    before do
      Dry::Logger.register_template(:my_details, "[%<severity>s] [%<time>s] %<message>s")
    end

    it "logs to $stdout by default using a registered template" do
      message = "hello, world"

      logger.info(message)

      expect(output).to eql("[INFO] [2017-01-15 16:00:23 +0100] hello, world\n")
    end
  end

  context "using external logger as backend" do
    subject(:logger) { Dry.Logger(:test, stream: stream).add_backend(backend) }

    context "with an stdlib logger" do
      let(:backend) { Logger.new(stream) }

      it "logs info messages" do
        backend.formatter = -> (_, _, _, msg) { msg }

        logger.info(message = "hello, world")

        expect(stream).to include(message)
      end
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

    context "log-file rotation" do
      let(:stream) { random_file_name(tmp: TMP) }
      let(:file_path_without_ext) { File.join(File.dirname(stream), File.basename(stream, ".*")) }

      context "default" do
        subject(:logger) { Dry.Logger(:test, stream: stream) }

        it "does not rotate logs by default" do
          2000.times { logger.info("Hello log message!") }

          expect(File.exist?("#{file_path_without_ext}.log")).to be true
          expect(File.exist?("#{file_path_without_ext}.log.1")).to be false
        end
      end

      context "based on size" do
        subject(:logger) { Dry.Logger(:test, stream: stream, shift_age: 3, shift_size: 10_000) }

        it "rotates logs based on shift_age and shift_size" do
          2000.times { logger.info("Hello log message!") }

          expect(File.exist?("#{file_path_without_ext}.log")).to be true
          expect(File.exist?("#{file_path_without_ext}.log.1")).to be true
          expect(File.exist?("#{file_path_without_ext}.log.2")).to be false
        end
      end

      context "based on period" do
        let(:now) { Time.parse("2025-06-06 07:07:23 +0100") }
        subject(:logger) { Dry.Logger(:test, stream: stream, shift_age: "daily") }

        before do
          # Ruby's logger reads the timestamp from the file for the base-time.
          # That's why we need to mock the mtime of the file with the spec's now.
          allow_any_instance_of(File::Stat).to receive(:mtime).and_return(now)
        end

        it "rotates logs based on period" do
          logger.info("Hello log message!")
          allow(Time).to receive(:now).and_return(now + (60 * 60 * 24))
          logger.info("Hello log message!")

          expect(File.exist?("#{file_path_without_ext}.log")).to be true
          expect(File.exist?("#{file_path_without_ext}.log.20250606")).to be true
        end

        context "with custom suffix" do
          subject(:logger) { Dry.Logger(:test, stream: stream, shift_age: "monthly", shift_period_suffix: "month%m") }

          it "rotates logs based on period" do
            logger.info("Hello log message!")
            allow(Time).to receive(:now).and_return(now + (60 * 60 * 24 * 30))
            logger.info("Hello log message!")

            expect(File.exist?("#{file_path_without_ext}.log")).to be true
            expect(File.exist?("#{file_path_without_ext}.log.month06")).to be true
          end
        end
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
    subject(:logger) { Dry.Logger(:test, stream: stream, formatter: nil) }

    it "falls back to string formatter" do
      logger.info("foo")

      expect(output).to eq "foo\n"
    end
  end
end
