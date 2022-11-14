# frozen_string_literal: true

RSpec.shared_context "stream" do
  let(:stream) do
    Class.new(StringIO) do
      def inspect
        string.inspect
      end

      def logged_lines
        string.split("\n")
      end

      def include?(log)
        logged_lines.include?(log)
      end
    end.new
  end

  let(:output) do
    stream.string
  end

  let(:now) do
    DateTime.parse("2017-01-15 16:00:23 +0100").to_time
  end

  before do
    allow(Time).to receive(:now).and_return(now)
  end
end
