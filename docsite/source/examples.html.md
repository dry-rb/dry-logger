---
title: Examples
layout: gem-single
name: dry-logger
---

This page shows complete, realistic configurations for common use cases, combining multiple dry-logger features.

## Development setup

Maximum readability with colorized output:

```ruby
require "dry/logger"

# Register a custom colorized template
Dry::Logger.register_template(
  :dev,
  "<gray>%<time>s</gray> <cyan>[%<progname>s]</cyan> " \
  "<yellow>%<severity>s</yellow> %<message>s <blue>%<payload>s</blue>"
)

logger = Dry.Logger(:my_app,
  template: :dev,
  level: :debug
)

logger.info("Server ready", port: 3000, env: "development")
# (colorized output) 2023-10-15 14:40:00 [my_app] INFO Server ready port=3000 env="development"
```

## Production setup

Structured JSON logging with error file and filters:

```ruby
require "dry/logger"

PRODUCTION_FILTERS = [
  :password,
  :api_key,
  :secret_token,
  :access_token,
  :ssn,
  :credit_card_number
].freeze

logger = Dry.Logger(:my_app) do |setup|
  # Main JSON log file
  setup.add_backend(
    stream: "logs/production.json",
    formatter: :json,
    filters: PRODUCTION_FILTERS
  )

  # Separate error file
  setup.add_backend(
    stream: "logs/errors.json",
    formatter: :json,
    filters: PRODUCTION_FILTERS,
    log_if: :error?
  )
end

logger.info("Request processed",
  user_id: 123,
  action: "update_profile",
  duration_ms: 45,
  password: "secret"  # Filtered
)
# {"progname":"my_app","severity":"INFO","time":"2023-10-15T14:42:30Z","message":"Request processed","user_id":123,"action":"update_profile","duration_ms":45,"password":"[FILTERED]"}
```

## Web applications

### Rack/Rails application

Combine different formatters and filters for different log types:

```ruby
require "dry/logger"

# Define filters for sensitive data
FILTER_PARAMS = [
  :password,
  :password_confirmation,
  :api_key,
  :secret_token,
  :access_token,
  :ssn,
  :credit_card_number
].freeze

logger = Dry.Logger(:rails_app) do |setup|
  # General application logs (string format)
  setup.add_backend(
    stream: "logs/application.log",
    formatter: :string,
    template: :details,
    filters: FILTER_PARAMS
  )

  # HTTP request logs (rack format)
  setup.add_backend(
    stream: "logs/requests.log",
    formatter: :rack,
    filters: FILTER_PARAMS,
    log_if: -> (entry) { entry.key?(:verb) && entry.key?(:path) }
  )

  # Error tracking in JSON
  setup.add_backend(
    stream: "logs/errors.json",
    formatter: :json,
    filters: FILTER_PARAMS,
    log_if: -> (entry) { entry.error? || entry.fatal? }
  )
end

# Application log
logger.info("User authenticated", user_id: 42)

# HTTP request log
logger.info(
  verb: "POST",
  path: "/api/users",
  status: 201,
  elapsed: "23ms",
  ip: "192.168.1.1",
  length: 512,
  params: {name: "John"}
)

# Error log
begin
  raise "Database timeout"
rescue => e
  logger.error(e)
end

# Use in Rails
Rails.logger = logger
```

## API applications

API-specific logging with custom templates and comprehensive filtering:

```ruby
require "dry/logger"

# API-specific filters
API_FILTERS = [
  # Auth headers
  :authorization,
  :api_key,
  "headers.authorization",
  "headers.x-api-key",

  # Request data
  :password,
  :secret,
  :token,

  # Response data
  "response.access_token",
  "response.refresh_token"
].freeze

# Custom template for API requests
Dry::Logger.register_template(
  :api,
  "%<time>s | %<verb>s %<path>s | Status: %<status>s | %<elapsed>s"
)

logger = Dry.Logger(:api) do |setup|
  # Console output for development
  setup.add_backend(
    stream: $stdout,
    formatter: :string,
    template: :api,
    filters: API_FILTERS
  )

  # JSON logs for aggregation
  setup.add_backend(
    stream: "logs/api.json",
    formatter: :json,
    filters: API_FILTERS
  )
end

logger.info(
  verb: "POST",
  path: "/api/orders",
  status: 201,
  elapsed: "120ms",
  authorization: "Bearer secret"  # Filtered
)
# Console: 2023-10-15 14:50:00 +0000 | POST /api/orders | Status: 201 | 120ms
# JSON: {"progname":"api",...,"authorization":"[FILTERED]"}
```

## Payment processing

PCI-compliant logging with comprehensive filters:

```ruby
require "dry/logger"

# PCI compliance filters
PAYMENT_FILTERS = [
  # Card data (PCI DSS requirement)
  :card_number,
  :cvv,
  :cvc,
  :expiry,
  :card_holder,
  "payment.card_number",
  "payment.cvv",

  # Billing data
  :billing_address,
  :account_number,
  :routing_number,

  # Customer PII
  :ssn,
  :tax_id,
  :email,
  :phone
].freeze

logger = Dry.Logger(:payment_processor,
  stream: "logs/payments.log",
  formatter: :json,
  filters: PAYMENT_FILTERS
)

logger.info("Payment processed",
  transaction_id: "txn_123",
  amount: 99.99,
  card_number: "4111111111111111",  # Will be filtered
  cvv: "123",                        # Will be filtered
  status: "success"
)
# {"transaction_id":"txn_123","amount":99.99,"card_number":"[FILTERED]","cvv":"[FILTERED]","status":"success"}
```

## Hybrid setup

Different backends for different purposes:

```ruby
require "dry/logger"

logger = Dry.Logger(:my_app) do |setup|
  # Colorized console for development
  setup.add_backend(
    stream: $stdout,
    formatter: :string,
    template: "<yellow>%<severity>s</yellow> %<message>s <blue>%<payload>s</blue>",
    log_if: -> (entry) { ENV["RACK_ENV"] == "development" }
  )

  # Detailed file logs
  setup.add_backend(
    stream: "logs/app.log",
    formatter: :string,
    template: :details
  )

  # JSON for analysis tools
  setup.add_backend(
    stream: "logs/app.json",
    formatter: :json
  )

  # Separate error file
  setup.add_backend(
    stream: "logs/errors.log",
    formatter: :string,
    template: :details,
    log_if: :error?
  )
end

logger.info("Application started", version: "1.2.3")
# Console: INFO Application started version="1.2.3" (colorized, development only)
# File: [my_app] [INFO] [2023-10-15 14:55:00 +0000] Application started version="1.2.3"
# JSON: {"progname":"my_app","severity":"INFO",...}
```

## Multi-environment configuration

Configure logger based on environment:

```ruby
require "dry/logger"

def setup_logger(env)
  case env
  when "development"
    Dry.Logger(:my_app,
      template: :dev,
      colorize: true,
      level: :debug
    )
  when "production"
    Dry.Logger(:my_app) do |setup|
      setup.add_backend(
        stream: "logs/production.json",
        formatter: :json,
        filters: production_filters
      )
      setup.add_backend(
        stream: "logs/errors.json",
        formatter: :json,
        filters: production_filters,
        log_if: :error?
      )
    end
  when "test"
    require "stringio"
    Dry.Logger(:my_app,
      stream: StringIO.new,
      level: :warn  # Suppress noise in tests
    )
  end
end

def production_filters
  [:password, :api_key, :secret_token, :ssn, :credit_card_number]
end

logger = setup_logger(ENV.fetch("RACK_ENV", "development"))
```
