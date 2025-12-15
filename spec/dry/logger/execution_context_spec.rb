# frozen_string_literal: true

require "dry/logger/execution_context"

RSpec.describe Dry::Logger::ExecutionContext do
  subject(:context) { described_class }

  after do
    context.clear
  end

  describe ".[]" do
    it "returns nil for unset keys" do
      expect(context[:nonexistent]).to be_nil
    end

    it "returns the value for set keys" do
      context[:test] = "value"
      expect(context[:test]).to eq("value")
    end
  end

  describe ".[]=" do
    it "sets a value for a key" do
      context[:key] = "value"
      expect(context[:key]).to eq("value")
    end

    it "overwrites existing values" do
      context[:key] = "old"
      context[:key] = "new"
      expect(context[:key]).to eq("new")
    end
  end

  describe ".clear" do
    it "removes all stored values" do
      context[:key1] = "value1"
      context[:key2] = "value2"

      context.clear

      expect(context[:key1]).to be_nil
      expect(context[:key2]).to be_nil
    end
  end

  describe "thread isolation" do
    it "isolates storage between threads" do
      context[:main] = "main_value"

      thread_value = nil
      thread = Thread.new do
        context[:thread] = "thread_value"
        thread_value = context[:main]
      end
      thread.join

      expect(context[:main]).to eq("main_value")
      expect(context[:thread]).to be_nil
      expect(thread_value).to be_nil
    end
  end
end
