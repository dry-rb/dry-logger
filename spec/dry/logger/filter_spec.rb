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

      it "filters nested paths that contain a filter" do
        filter = described_class.new(%w[user.token])
        result = filter.call(superuser: {tokens: "abc123"})

        expect(result[:superuser][:tokens]).to eq("[FILTERED]")
      end
    end

    context "with key and path filters together" do
      subject(:filter) { described_class.new(%w[token user.password]) }

      it "applies both kinds of filter" do
        input = {auth_token: "abc123", user: {password: "secret"}, admin: {password: "keep-this"}}
        result = filter.call(input)

        expect(result[:auth_token]).to eq("[FILTERED]")
        expect(result[:user][:password]).to eq("[FILTERED]")
        expect(result[:admin][:password]).to eq("keep-this")
      end

      it "applies both kinds of filter to literal keys that contain a dot" do
        input = {"session.token" => "abc123", "user.password" => "secret"}
        result = filter.call(input)

        expect(result["session.token"]).to eq("[FILTERED]")
        expect(result["user.password"]).to eq("[FILTERED]")
      end
    end

    context "with substring matching" do
      subject(:filter) { described_class.new(%w[passw token]) }

      it "filters keys that contain a filter" do
        input = {password_confirmation: "secret", user_password: "secret", user: "john"}
        result = filter.call(input)

        expect(result[:password_confirmation]).to eq("[FILTERED]")
        expect(result[:user_password]).to eq("[FILTERED]")
        expect(result[:user]).to eq("john")
      end

      it "ignores case" do
        result = filter.call("X-Auth-TOKEN" => "abc123")

        expect(result["X-Auth-TOKEN"]).to eq("[FILTERED]")
      end

      it "does not treat regexp syntax in strings as a regexp" do
        filter = described_class.new(["^password$"])
        input = {password: "keep", "^password$" => "secret"}
        result = filter.call(input)

        expect(result[:password]).to eq("keep")
        expect(result["^password$"]).to eq("[FILTERED]")
      end
    end

    context "with symbol filters" do
      subject(:filter) { described_class.new(%i[password]) }

      it "filters keys that contain a filter" do
        result = filter.call(password_confirmation: "secret")

        expect(result[:password_confirmation]).to eq("[FILTERED]")
      end
    end

    context "with regexp filters" do
      subject(:filter) { described_class.new([/\Apin\z/, /\Acard\.number\z/]) }

      it "filters keys that match a regexp" do
        input = {pin: "1234", pinned: true}
        result = filter.call(input)

        expect(result[:pin]).to eq("[FILTERED]")
        expect(result[:pinned]).to eq(true)
      end

      it "filters nested keys that match a regexp" do
        result = filter.call(user: {pin: "1234"})

        expect(result[:user][:pin]).to eq("[FILTERED]")
      end

      it "filters keys whose full dotted path matches a regexp" do
        input = {card: {number: "4545"}, number: "42"}
        result = filter.call(input)

        expect(result[:card][:number]).to eq("[FILTERED]")
        expect(result[:number]).to eq("42")
      end
    end

    context "with blank filters" do
      it "ignores blank filters, with a warning" do
        filter = nil
        expect { filter = described_class.new(["", "password"]) }
          .to output(/\Adry-logger: ignoring blank log filter\(s\)\./).to_stderr

        result = filter.call(password: "secret", user: "john")

        expect(result[:password]).to eq("[FILTERED]")
        expect(result[:user]).to eq("john")
      end

      it "does not warn when there are no blank filters" do
        expect { described_class.new(["password"]) }.not_to output.to_stderr
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

    context "with arrays" do
      subject(:filter) { described_class.new(%w[password tokens]) }

      it "filters hashes inside arrays" do
        input = {users: [{password: "secret", name: "john"}, {password: "secret2", name: "jane"}]}
        result = filter.call(input)

        expect(result[:users]).to eq(
          [{password: "[FILTERED]", name: "john"}, {password: "[FILTERED]", name: "jane"}]
        )
      end

      it "filters hashes inside nested arrays" do
        input = {groups: [[{password: "secret", name: "john"}]]}
        result = filter.call(input)

        expect(result[:groups]).to eq([[{password: "[FILTERED]", name: "john"}]])
      end

      it "filters every item when the array's key matches" do
        input = {tokens: ["abc", {value: "def"}], names: ["john", "jane"]}
        result = filter.call(input)

        expect(result[:tokens]).to eq(["[FILTERED]", {value: "[FILTERED]"}])
        expect(result[:names]).to eq(["john", "jane"])
      end

      it "uses the array's key in dotted paths" do
        filter = described_class.new(%w[users.password])
        input = {users: [{password: "secret", name: "john"}]}
        result = filter.call(input)

        expect(result[:users]).to eq([{password: "[FILTERED]", name: "john"}])
      end

      it "does not mutate the original arrays" do
        input = {users: [{password: "secret"}]}

        filter.call(input)

        expect(input).to eq(users: [{password: "secret"}])
      end
    end
  end
end
