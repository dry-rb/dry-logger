# frozen_string_literal: true

RSpec.describe Dry::Logger::Filter do
  describe "#call" do
    context "with single-level hash" do
      subject(:filter) { described_class.new(%w[password token]) }

      it "filters matching keys" do
        input = {password: "secret", token: "abc123", user: "john"}
        result = filter.call(input)

        expect(result[:password]).to eq("[FILTERED]")
        expect(result[:token]).to eq("[FILTERED]")
        expect(result[:user]).to eq("john")
      end

      it "does not mutate the original hash" do
        input = {password: "secret", token: "abc123"}
        original = input.dup

        filter.call(input)

        expect(input).to eq(original)
      end

      it "works with string keys" do
        input = {"password" => "secret", "user" => "john"}
        result = filter.call(input)

        expect(result["password"]).to eq("[FILTERED]")
        expect(result["user"]).to eq("john")
      end

      it "filters nil values" do
        input = {password: nil, user: "john"}
        result = filter.call(input)

        expect(result[:password]).to eq("[FILTERED]")
        expect(result[:user]).to eq("john")
      end

      it "handles an empty hash" do
        result = filter.call({})
        expect(result).to eq({})
      end
    end

    context "with nested hashes" do
      subject(:filter) { described_class.new(%w[password]) }

      it "filters nested keys" do
        input = {user: {password: "secret", name: "john"}}
        result = filter.call(input)

        expect(result[:user][:password]).to eq("[FILTERED]")
        expect(result[:user][:name]).to eq("john")
      end

      it "does not mutate nested hashes" do
        input = {user: {password: "secret", name: "john"}}
        original = Marshal.load(Marshal.dump(input))

        filter.call(input)

        expect(input).to eq(original)
        expect(input[:user][:password]).to eq("secret")
      end

      it "filters deeply nested keys" do
        input = {
          level1: {
            level2: {
              level3: {password: "secret", data: "keep"}
            }
          }
        }
        result = filter.call(input)

        expect(result[:level1][:level2][:level3][:password]).to eq("[FILTERED]")
        expect(result[:level1][:level2][:level3][:data]).to eq("keep")
      end
    end

    context "with dot notation" do
      subject(:filter) { described_class.new(%w[user.password credentials.api_key]) }

      it "filters specific nested paths" do
        input = {
          user: {password: "secret", name: "john"},
          admin: {password: "keep-this"},
          credentials: {api_key: "key123", public_key: "pub456"}
        }
        result = filter.call(input)

        expect(result[:user][:password]).to eq("[FILTERED]")
        expect(result[:user][:name]).to eq("john")
        expect(result[:admin][:password]).to eq("keep-this")
        expect(result[:credentials][:api_key]).to eq("[FILTERED]")
        expect(result[:credentials][:public_key]).to eq("pub456")
      end
    end

    context "with parent key filtering" do
      subject(:filter) { described_class.new(%w[credentials]) }

      it "filters all nested keys when parent is filtered" do
        input = {
          credentials: {
            username: "user",
            password: "pass",
            nested: {secret: "data"}
          },
          public: "info"
        }
        result = filter.call(input)

        # When parent key matches, all children are filtered
        expect(result[:credentials][:username]).to eq("[FILTERED]")
        expect(result[:credentials][:password]).to eq("[FILTERED]")
        expect(result[:credentials][:nested][:secret]).to eq("[FILTERED]")
        expect(result[:public]).to eq("info")
      end
    end

    context "with mixed key types" do
      subject(:filter) { described_class.new(%w[password token]) }

      it "filters symbol keys" do
        input = {password: "secret", token: "abc", user: "john"}
        result = filter.call(input)

        expect(result[:password]).to eq("[FILTERED]")
        expect(result[:token]).to eq("[FILTERED]")
        expect(result[:user]).to eq("john")
      end

      it "filters string keys" do
        input = {"password" => "secret", "token" => "abc", "user" => "john"}
        result = filter.call(input)

        expect(result["password"]).to eq("[FILTERED]")
        expect(result["token"]).to eq("[FILTERED]")
        expect(result["user"]).to eq("john")
      end
    end

    context "with empty filters" do
      subject(:filter) { described_class.new([]) }

      it "returns the hash unchanged" do
        input = {password: "secret", token: "abc"}
        result = filter.call(input)

        expect(result).to eq(input)
      end

      it "does not mutate the original" do
        input = {password: "secret"}
        original = input.dup

        filter.call(input)

        expect(input).to eq(original)
      end
    end

    context "with non-hash enumerables" do
      subject(:filter) { described_class.new(%w[password]) }

      it "does not attempt to filter array values" do
        input = {
          users: [{password: "secret", name: "john"}],
          password: "filtered"
        }
        result = filter.call(input)

        # Top-level password is filtered
        expect(result[:password]).to eq("[FILTERED]")
        # Array is left as-is (filtering doesn't traverse arrays)
        expect(result[:users]).to eq([{password: "secret", name: "john"}])
      end
    end
  end
end
