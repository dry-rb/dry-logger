---
title: Context
layout: gem-single
name: dry-logger
---

Context allows you to define payload data included in every log entry, useful for adding request IDs, user IDs, or other contextual information spanning multiple log entries.

## Basic context usage

```ruby
logger = Dry.Logger(:my_app)

# Set context data
logger.context[:request_id] = "req-123"
logger.context[:user_id] = 42

# All subsequent logs include context automatically
logger.info("User action", action: "login")
# User action request_id="req-123" user_id=42 action="login"

logger.info("Profile updated")
# Profile updated request_id="req-123" user_id=42
```

## Request-scoped context

Context is thread-local by default, making it perfect for web applications where each request runs in its own thread:

```ruby
# In your Rack middleware or Rails controller
class RequestLogger
  def call(env)
    request = Rack::Request.new(env)

    logger.context[:request_id] = request.request_id
    logger.context[:ip] = request.ip
    logger.context[:method] = request.request_method
    logger.context[:path] = request.path

    logger.info("Request started")
    # Request started request_id="..." ip="192.168.1.1" method="GET" path="/users"

    @app.call(env)
  ensure
    # Context automatically clears when thread ends
    logger.context.clear
  end
end
```

## Isolated context

You can create a logger with an isolated context (not thread-local):

```ruby
logger = Dry.Logger(:my_app, context: {})

logger.context[:component] = "database"

logger.info("Connection opened")
# Connection opened component="database"
```

## Context best practices

**Do** use context for request-scoped data:

```ruby
# Good - data relevant to all logs in this request
logger.context[:request_id] = request.id
logger.context[:user_id] = current_user.id
logger.context[:tenant_id] = current_tenant.id
```

**Don't** use context for log-specific data:

```ruby
# Bad - this should be in the log entry itself
logger.context[:action] = "login"
logger.info("User action")  # Wrong approach

# Good - put it in the specific log entry
logger.info("User action", action: "login")
```
