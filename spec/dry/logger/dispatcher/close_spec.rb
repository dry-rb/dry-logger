# frozen_string_literal: true

RSpec.describe Dry::Logger::Dispatcher, "#close" do
  subject(:logger) { Dry.Logger(:test, stream: stream) }

  before do
    logger.close
  end

  context "when stream is $stdout" do
    let(:stream) { $stdout }

    it "does not close stream" do
      expect { print "in $stdout" }.to output("in $stdout").to_stdout
    end
  end

  context "when stream is a file" do
    let(:stream) { random_file_name }

    it "closes stream" do
      logger.info(message = "foo")

      expect(read(stream)).to_not match(message)
    end
  end

  context "when stream is StringIO" do
    let(:stream) { StringIO.new }

    it "closes stream" do
      logger.info("foo")

      expect { read(stream) }.to raise_error(IOError)
    end
  end

  context "when stream is IO" do
    let(:stream) { io_stream(destination) }
    let(:destination) { file_with_directory }

    it "closes stream" do
      logger.info(message = "foo")
      logger.close

      expect(read(destination)).to_not match(message)
    end
  end
end
