---
title: Testing
layout: gem-single
name: dry-logger
---

When testing applications that use dry-logger, you'll want to verify that your code logs correctly without cluttering test output.

## Using StringIO

The simplest approach is to log to a `StringIO` object, which you can inspect in your tests:

```ruby
require "stringio"

RSpec.describe MyClass do
  let(:log_output) { StringIO.new }
  let(:logger) { Dry.Logger(:test, stream: log_output) }

  it "logs the operation" do
    subject = MyClass.new(logger: logger)
    subject.perform

    expect(log_output.string).to include("Operation completed")
  end
end
```

## Testing log content

### String format

For human-readable assertions:

```ruby
RSpec.describe UserService do
  let(:log_output) { StringIO.new }
  let(:logger) do
    Dry.Logger(:test,
      stream: log_output,
      formatter: :string,
      template: :details
    )
  end

  it "logs user creation" do
    service = UserService.new(logger: logger)
    service.create_user(email: "test@example.com")

    expect(log_output.string).to include("User created")
    expect(log_output.string).to include('email="test@example.com"')
  end
end
```

### JSON format

For structured assertions:

```ruby
RSpec.describe UserService do
  let(:log_output) { StringIO.new }
  let(:logger) do
    Dry.Logger(:test, stream: log_output, formatter: :json)
  end

  it "logs user creation with correct data" do
    service = UserService.new(logger: logger)
    service.create_user(email: "test@example.com")

    log_entry = JSON.parse(log_output.string)
    expect(log_entry["message"]).to eq("User created")
    expect(log_entry["severity"]).to eq("INFO")
    expect(log_entry["email"]).to eq("test@example.com")
  end
end
```

### Testing multiple log entries

When your code logs multiple times:

```ruby
RSpec.describe OrderProcessor do
  let(:log_output) { StringIO.new }
  let(:logger) { Dry.Logger(:test, stream: log_output, formatter: :json) }

  it "logs each step of order processing" do
    processor = OrderProcessor.new(logger: logger)
    processor.process(order_id: 123)

    logs = log_output.string.split("\n").map { |line| JSON.parse(line) }

    expect(logs[0]["message"]).to eq("Order received")
    expect(logs[1]["message"]).to eq("Payment processed")
    expect(logs[2]["message"]).to eq("Order completed")
  end
end
```

## Testing log levels

Verify that your code logs at the correct severity:

```ruby
RSpec.describe ErrorHandler do
  let(:log_output) { StringIO.new }
  let(:logger) { Dry.Logger(:test, stream: log_output, formatter: :json) }

  it "logs errors at ERROR level" do
    handler = ErrorHandler.new(logger: logger)
    handler.handle_error(StandardError.new("Something went wrong"))

    log_entry = JSON.parse(log_output.string)
    expect(log_entry["severity"]).to eq("ERROR")
    expect(log_entry["message"]).to eq("Something went wrong")
  end
end
```

## Suppressing logs in tests

### Null device

Send logs to the null device to discard them:

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.around(:each) do |example|
    # Suppress all logging during tests
    logger = Dry.Logger(:test, stream: File.open(File::NULL, "w"))

    # Make it available to your app
    allow(MyApp).to receive(:logger).and_return(logger)

    example.run
  end
end
```

### High log level

Set the log level to `:fatal` or above to suppress most logs:

```ruby
RSpec.configure do |config|
  config.before(:each) do
    @original_logger = MyApp.logger
    MyApp.logger = Dry.Logger(:test, level: :fatal)
  end

  config.after(:each) do
    MyApp.logger = @original_logger
  end
end
```

### Per-test control

Use RSpec metadata to control logging per test:

```ruby
RSpec.configure do |config|
  config.around(:each) do |example|
    if example.metadata[:show_logs]
      example.run
    else
      logger = Dry.Logger(:test, stream: File.open(File::NULL, "w"))
      allow(MyApp).to receive(:logger).and_return(logger)
      example.run
    end
  end
end

# Enable logging for specific tests
RSpec.describe MyClass do
  it "does something", show_logs: true do
    # Logs will be visible for this test
  end

  it "does something else" do
    # Logs suppressed (default)
  end
end
```

## Testing with dependency injection

Make loggers injectable for easier testing:

```ruby
class UserService
  def initialize(logger: Dry.Logger(:user_service))
    @logger = logger
  end

  def create_user(email:)
    @logger.info("Creating user", email: email)
    # ... create user
    @logger.info("User created", email: email)
  end
end

# In tests
RSpec.describe UserService do
  let(:log_output) { StringIO.new }
  let(:logger) { Dry.Logger(:test, stream: log_output) }
  let(:service) { UserService.new(logger: logger) }

  it "logs user creation" do
    service.create_user(email: "test@example.com")
    expect(log_output.string).to include("User created")
  end
end
```

## Testing filters

Verify that sensitive data is properly filtered:

```ruby
RSpec.describe PaymentProcessor do
  let(:log_output) { StringIO.new }
  let(:logger) do
    Dry.Logger(:test,
      stream: log_output,
      formatter: :json,
      filters: [:card_number, :cvv]
    )
  end

  it "filters sensitive payment data" do
    processor = PaymentProcessor.new(logger: logger)
    processor.process(card_number: "4111111111111111", cvv: "123", amount: 99.99)

    log_entry = JSON.parse(log_output.string)
    expect(log_entry["card_number"]).to eq("[FILTERED]")
    expect(log_entry["cvv"]).to eq("[FILTERED]")
    expect(log_entry["amount"]).to eq(99.99)
  end
end
```

## Testing custom formatters

If you've created custom formatters, test them directly:

```ruby
RSpec.describe MyCustomFormatter do
  let(:formatter) { MyCustomFormatter.new }
  let(:entry) do
    Dry::Logger::Entry.new(
      clock: Dry::Logger::Clock.new,
      progname: "test",
      severity: :info,
      message: "Test message",
      payload: {user_id: 42}
    )
  end

  it "formats entries correctly" do
    output = formatter.call(:info, Time.now, "test", entry)
    expect(output).to include("Test message")
    expect(output).to include("user_id=42")
  end
end
```
