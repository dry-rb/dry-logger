---
title: Backends
layout: gem-single
name: dry-logger
---

Backends are responsible for writing log entries to specific destinations. dry-logger supports multiple backends, allowing you to log to several destinations simultaneously with different configurations for each.

## Understanding backends

A backend combines:

- An **output destination** (stdout, file, external logger, etc.)
- A **formatter** (how entries are formatted)
- Optional **conditional logging** (when to log)

## Multiple backends

### Adding backends

Add backends to the default logger:

```ruby
logger = Dry.Logger(:my_app)
  .add_backend(stream: "logs/application.log")
  .add_backend(stream: "logs/errors.log", log_if: :error?)

logger.info("User logged in")
# Goes to stdout and logs/application.log

logger.error("Database connection failed")
# Goes to stdout, logs/application.log, and logs/errors.log
```

### Block-based configuration

For more control, configure all backends in a block:

```ruby
logger = Dry.Logger(:my_app) do |setup|
  setup.add_backend(stream: "logs/application.log", template: :details)
  setup.add_backend(stream: "logs/json.log", formatter: :json)
end

# Only logs to the files you configured (no stdout)
```

When you use a block, dry-logger skips creating the default stdout backend, giving you complete control.

## Conditional logging

The `log_if` option controls when a backend should log an entry. This is useful for routing different log levels to different destinations.

### Using severity methods

Filter by log level using the entry's severity methods:

```ruby
logger = Dry.Logger(:my_app)
  .add_backend(
    stream: "logs/errors.log",
    log_if: :error?  # Only log ERROR and FATAL
  )

logger.info("Normal operation")  # Not logged to errors.log
logger.error("Something broke")  # Logged to errors.log
```

Available severity methods:

- `:debug?` - Only DEBUG messages
- `:info?` - Only INFO messages
- `:warn?` - Only WARN messages
- `:error?` - Only ERROR messages
- `:fatal?` - Only FATAL messages

### Using custom procs

For more complex filtering, use a proc that receives the log entry:

```ruby
logger = Dry.Logger(:my_app)
  .add_backend(
    stream: "logs/requests.log",
    log_if: -> (entry) { entry.key?(:request) }
  )

logger.info("User logged in", request: true, path: "/login")
# Logged to logs/requests.log

logger.info("Cache cleared")
# Not logged to logs/requests.log
```

The entry object provides several useful methods:

```ruby
log_if: -> (entry) {
  # Check severity
  entry.error? || entry.fatal?

  # Check for specific keys in payload
  entry.key?(:database)

  # Access payload values
  entry[:user_id] == 123

  # Check tags
  entry.tag?(:production)
}
```

### Multiple conditions example

Route different types of logs to different files:

```ruby
logger = Dry.Logger(:my_app) do |setup|
  # All logs in detailed format
  setup.add_backend(
    stream: "logs/all.log",
    template: :details
  )

  # Only errors in JSON format for monitoring tools
  setup.add_backend(
    stream: "logs/errors.json",
    formatter: :json,
    log_if: -> (entry) { entry.error? || entry.fatal? }
  )

  # Only HTTP requests
  setup.add_backend(
    stream: "logs/requests.log",
    formatter: :rack,
    log_if: -> (entry) { entry.key?(:verb) && entry.key?(:path) }
  )

  # Performance logs
  setup.add_backend(
    stream: "logs/performance.log",
    log_if: -> (entry) { entry.key?(:elapsed) }
  )
end
```

## Backend configuration options

Each backend supports several configuration options:

```ruby
logger.add_backend(
  stream: "logs/app.log",      # Output destination
  formatter: :json,             # Formatter to use (:string, :json, :rack)
  template: :details,           # Template for string formatter
  level: :warn,                 # Minimum level for this backend
  log_if: :error?,             # Conditional logging
  shift_age: 5,                # Log rotation: number of old files
  shift_size: 1048576,         # Log rotation: max file size
  colorize: true,              # Enable colorized output
  severity_colors: {           # Custom severity colors
    error: :red,
    warn: :yellow
  }
)
```

## Using external loggers

### Standard library logger

You can use Ruby's standard library `Logger` as a backend:

```ruby
require "logger"

stdlib_logger = Logger.new("logs/stdlib.log")
stdlib_logger.formatter = proc { |severity, datetime, progname, msg|
  "[#{severity}] #{msg}\n"
}

logger = Dry.Logger(:my_app).add_backend(stdlib_logger)

logger.info("Test message")
# Written to both dry-logger default output and stdlib.log
```

### Conditional external loggers

Apply conditional logging to external loggers too:

```ruby
error_logger = Logger.new("logs/errors.log")

logger = Dry.Logger(:my_app)
  .add_backend(error_logger) { |backend|
    backend.log_if = :error?.to_proc
  }
```

## Log rotation

dry-logger supports Ruby's `Logger` log rotation features for file-based backends.

### Size-based rotation

Keep a fixed number of log files with a maximum size:

```ruby
# Keep 5 log files, 10MB each
logger = Dry.Logger(:my_app,
  stream: "logs/app.log",
  shift_age: 5,
  shift_size: 10_485_760  # 10 megabytes
)
```

When `app.log` reaches 10MB, it's renamed to `app.log.1`, and a new `app.log` is created. This continues up to `app.log.5`, at which point the oldest file is deleted.

### Time-based rotation

Rotate logs by time period:

```ruby
# Rotate daily
logger = Dry.Logger(:my_app,
  stream: "logs/app.log",
  shift_age: "daily"
)

# Rotate weekly
logger = Dry.Logger(:my_app,
  stream: "logs/app.log",
  shift_age: "weekly"
)

# Rotate monthly
logger = Dry.Logger(:my_app,
  stream: "logs/app.log",
  shift_age: "monthly"
)
```

Rotated files are named with timestamps (e.g., `app.log.20231015`).

### Custom rotation suffix

Customize the timestamp format for rotated files:

```ruby
logger = Dry.Logger(:my_app,
  stream: "logs/app.log",
  shift_age: "monthly",
  shift_period_suffix: "month%m"  # e.g., app.log.month10
)
```

## Managing backends

### Closing backends

When you're done with a logger, close all backends to flush buffers and release file handles:

```ruby
logger = Dry.Logger(:my_app, stream: "logs/app.log")

logger.info("Final message")

logger.close  # Flushes and closes all backends
```

### Inspecting backends

View configured backends:

```ruby
logger = Dry.Logger(:my_app)
  .add_backend(stream: "logs/app.log")

logger.backends
# => [#<Dry::Logger::Backends::Stream...>, #<Dry::Logger::Backends::File...>]

logger.backends.size
# => 2
```
