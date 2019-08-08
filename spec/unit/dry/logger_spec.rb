# frozen_string_literal: true

RSpec.describe Dry::Logger do
  describe "#initialize" do
    it "returns a frozen instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
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
