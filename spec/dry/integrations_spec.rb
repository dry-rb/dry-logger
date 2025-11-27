# frozen_string_literal: true

require "sequel"

RSpec.describe "Dry.Logger" do
  include_context "stream"

  before do
    allow(Time).to receive(:now).and_return(DateTime.parse("2017-01-15 16:00:23 +0100").to_time)
  end

  context "Sequel" do
    let(:logger) do
      Dry.Logger(:test, stream: stream)
    end

    let(:sequel) do
      if RUBY_PLATFORM == "java"
        Sequel.connect("jdbc:sqlite::memory:")
      else
        Sequel.sqlite
      end
    end

    before do
      sequel.logger = logger
    end

    it "logs Sequel messages" do
      sequel.create_table(:users) { primary_key(:id) }

      expect(stream.logged_lines[0]).to include("CREATE TABLE `users`")
    end
  end
end
