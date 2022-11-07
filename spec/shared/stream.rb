RSpec.shared_context "stream" do
  let(:stream) do
    Class.new(StringIO) do
      def logged_lines
        string.split("\n")
      end

      def include?(log)
        logged_lines.include?(log)
      end
    end.new
  end
end
