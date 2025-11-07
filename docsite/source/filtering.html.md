---
title: Filtering sensitive data
layout: gem-single
name: dry-logger
---

When logging in production environments, you often need to filter sensitive information like passwords, API keys, credit card numbers, and personal data from your logs. dry-logger provides a flexible filtering mechanism to redact sensitive data.

## Basic filtering

Use the `filters` option to specify which keys should be filtered from log payloads:

```ruby
logger = Dry.Logger(:my_app,
  filters: [:password, :api_key, :ssn]
)

logger.info("User signup",
  email: "user@example.com",
  password: "secret123",
  api_key: "sk_live_1234567890"
)
# email="user@example.com" password="[FILTERED]" api_key="[FILTERED]"
```

Filtered values are replaced with the string `"[FILTERED]"`.

## How filters match

Filters match **exact key names** or **dot-separated paths** for nested data. They do NOT match partial key names:

```ruby
logger = Dry.Logger(:my_app, filters: [:password])

logger.info(password: "secret")          # password="[FILTERED]"
logger.info(user_password: "secret")     # user_password="secret" (NOT filtered)
logger.info(password_hash: "abc123")     # password_hash="abc123" (NOT filtered)
```

To filter keys like `user_password`, you must explicitly list them:

```ruby
logger = Dry.Logger(:my_app, filters: [:password, :user_password, :password_hash])
```

## Nested data filtering

Filters work with nested hashes using dot notation:

```ruby
logger = Dry.Logger(:my_app,
  filters: ["user.password", "credit_card.number"]
)

logger.info("Payment processed",
  user: {
    email: "user@example.com",
    password: "secret"
  },
  credit_card: {
    number: "4111111111111111",
    expiry: "12/25"
  }
)
# user={"email"=>"user@example.com", "password"=>"[FILTERED]"}
# credit_card={"number"=>"[FILTERED]", "expiry"=>"12/25"}
```

## Per-backend filtering

Different backends can have different filters:

```ruby
logger = Dry.Logger(:my_app) do |setup|
  # Development logs: minimal filtering
  setup.add_backend(
    stream: $stdout,
    filters: [:password, :api_key]
  )

  # Production logs: aggressive filtering
  setup.add_backend(
    stream: "logs/production.log",
    formatter: :json,
    filters: [
      :password, :api_key, :token, :secret,
      :ssn, :email, :phone, :address,
      :credit_card, :card_number, :cvv
    ]
  )
end
```

## Limitations

### Filters work on structured logs only

Filters operate on structures logs only. This means that when logging an exception, its backtrace and message are **not** filtered. Avoid including sensitive data in exception messages:

```ruby
# DON'T do this - password will appear in logs
raise "Failed to authenticate with password: #{password}"

# DO this instead - password is filtered from payload
logger.error("Failed to authenticate", password: password, error: "auth_failed")
```

### No filtering within arrays

Filters work on hash structures but do not traverse arrays. If your payload contains arrays of hashes, the values inside those arrays won't be filtered:

```ruby
logger = Dry.Logger(:my_app, filters: [:password])

logger.info(
  password: "filtered",           # Will be filtered
  users: [
    {name: "Alice", password: "secret"}  # password inside array NOT filtered
  ]
)
```
