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
    it "makes copy on write in new thread" do
      context[:main] = "main_value"

      thread = Thread.new do
        context[:main] = "new_value"
        context[:fiber] = "fiber_value"
      end
      thread.join

      expect(context[:main]).to eq("main_value")
      expect(context[:fiber]).to be_nil
    end

    it "inherits parent thread fiber storage in new thread" do
      context[:main] = "main_value"

      thread_value = nil
      thread = Thread.new do
        thread_value = context[:main]
      end
      thread.join

      expect(context[:main]).to eq("main_value")
      expect(thread_value).to eq("main_value")
    end
  end

  describe "fiber isolation" do
    it "makes copy on write in new fiber" do
      context[:main] = "main_value"

      fiber = Fiber.new do
        context[:main] = "new_value"
        context[:fiber] = "fiber_value"
      end
      fiber.resume

      expect(context[:main]).to eq("main_value")
      expect(context[:fiber]).to be_nil
    end

    it "inherits parent storage in new fiber" do
      context[:main] = "main_value"

      fiber_value = nil
      fiber = Fiber.new do
        fiber_value = context[:main]
      end
      fiber.resume

      expect(context[:main]).to eq("main_value")
      expect(fiber_value).to eq("main_value")
    end
  end
end
