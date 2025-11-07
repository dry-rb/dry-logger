---
title: Tagged logging
layout: gem-single
name: dry-logger
---

Tags allow you to mark log entries within a specific block, useful for grouping related operations or marking logs from specific components.

## Basic tagging

```ruby
logger = Dry.Logger(:my_app,
  template: "[%<tags>s] %<message>s %<payload>s"
)

logger.tagged(:database) do
  logger.info("Connection opened", pool_size: 5)
  logger.info("Query executed", duration_ms: 23)
end
# [database] Connection opened pool_size=5
# [database] Query executed duration_ms=23

logger.info("Outside tagged block")
# [] Outside tagged block
```

## Multiple tags

```ruby
logger.tagged(:api, :production) do
  logger.info("Request processed")
end
# [api production] Request processed
```

## Hash tags

Tags can be hashes for structured tagging:

```ruby
logger.tagged(component: "auth", version: "v2") do
  logger.info("Authentication attempt")
end
# [component="auth" version="v2"] Authentication attempt
```

## Mixing tag types

```ruby
logger.tagged(:production, component: "database") do
  logger.info("Slow query", duration_ms: 500)
end
# [production component="database"] Slow query duration_ms=500
```

## Filtering by tags

Tags are particularly powerful when combined with conditional logging:

```ruby
logger = Dry.Logger(:my_app, context: {}) do |setup|
  # Only log database operations to this file
  setup.add_backend(
    stream: "logs/database.log",
    log_if: -> (entry) { entry.tag?(:database) }
  )

  # Only log API operations to this file
  setup.add_backend(
    stream: "logs/api.log",
    log_if: -> (entry) { entry.tag?(:api) }
  )

  # Everything goes to main log
  setup.add_backend(stream: "logs/all.log")
end

logger.tagged(:database) do
  logger.info("Query executed")  # Goes to database.log and all.log
end

logger.tagged(:api) do
  logger.info("Request received")  # Goes to api.log and all.log
end

logger.info("General message")  # Only goes to all.log
```

## Nested tags

Tags only apply within their block and don't nest:

```ruby
logger.tagged(:outer) do
  logger.info("Outer")  # [outer]

  logger.tagged(:inner) do
    logger.info("Inner")  # [inner] (not [outer inner])
  end

  logger.info("Outer again")  # [outer]
end
```
