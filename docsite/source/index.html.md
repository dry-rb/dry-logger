---
title: Introduction
description: Standalone, structured logging for Ruby
layout: gem-single
type: gem
name: dry-logger
sections:
  - backends
  - formatters
  - templates
  - filtering
  - context
  - tagging
  - crash-handling
  - testing
  - examples
---

dry-logger is a standalone, dependency-free logging solution for Ruby applications.

## Features

- **Structured logging** - First-class support for key-value payloads
- **Multiple destinations** - Log to stdout, files, or multiple backends simultaneously
- **Flexible formatting** - String, JSON, and Rack formatters included
- **Data filtering** - Redact sensitive information from logs
- **Exception handling** - Automatic formatting of exceptions with backtraces
- **Customizable templates** - Control log format with colorization support
- **Extensible** - Add custom backends and formatters

## Installation

Add dry-logger to your Gemfile:

```ruby
gem "dry-logger"
```

## Getting started

Create a logger and start logging:

```ruby
require "dry/logger"

logger = Dry.Logger(:my_app)

logger.info("Application started")
# Application started

logger.warn("Low memory warning")
# Low memory warning

logger.error("Failed to connect to database")
# Failed to connect to database
```

### Log levels

Set the minimum severity level to control which messages are logged:

```ruby
logger = Dry.Logger(:my_app, level: :warn)

logger.debug("Debug message")  # Won't be logged
logger.info("Info message")    # Won't be logged
logger.warn("Warning message") # Will be logged
logger.error("Error message")  # Will be logged
```

Available levels (lowest to highest): `:debug`, `:info` (default), `:warn`, `:error`, `:fatal`, `:unknown`

### Structured logging

Attach key-value data to log entries:

```ruby
logger = Dry.Logger(:my_app)

# Log with structured data
logger.info("User logged in", user_id: 42, ip: "192.168.1.1")
# User logged in user_id=42 ip="192.168.1.1"

# Log only structured data (no message)
logger.info(action: "signup", user_id: 123, plan: "premium")
# action="signup" user_id=123 plan="premium"
```

### Logging exceptions

Exceptions are automatically formatted with their message, class, and backtrace:

```ruby
begin
  1 / 0
rescue => e
  logger.error(e)
  # ZeroDivisionError: divided by 0
  #   /path/to/file.rb:10:in `/'
  #   /path/to/file.rb:10:in `<main>'
end
```

### Block-based logging

For expensive operations, use blocks to avoid computing messages unless they'll actually be logged:

```ruby
logger = Dry.Logger(:my_app, level: :info)

# Block is NOT evaluated (debug < info)
logger.debug { expensive_debug_info }

# Block IS evaluated
logger.info { "User count: #{User.count}" }
# User count: 42
```

Blocks can also return structured data:

```ruby
logger.info { {action: "cache_miss", key: "user:123"} }
# action="cache_miss" key="user:123"
```

### Customizing progname per entry

Override the logger's default progname for specific log entries:

```ruby
logger = Dry.Logger(:my_app)

# Use progname keyword
logger.info("Request received", progname: "http_server", path: "/api/users")
# Logs with progname "http_server" instead of "my_app"

# Or pass as first argument with block-based logging
logger.info("worker") { "Job completed" }
# Logs with progname "worker"
```

## Output streams

### Standard output (default)

```ruby
logger = Dry.Logger(:my_app)  # Logs to $stdout
```

### Files

```ruby
logger = Dry.Logger(:my_app, stream: "logs/application.log")  # Relative path
logger = Dry.Logger(:my_app, stream: "/var/log/app.log")      # Absolute path
```

### StringIO (testing)

```ruby
require "stringio"

output = StringIO.new
logger = Dry.Logger(:my_app, stream: output)

logger.info("Test message")

puts output.string
# Test message
```

## Multiple destinations

### Using add_backend

Add backends to the default logger:

```ruby
logger = Dry.Logger(:test, template: :details)
  .add_backend(stream: "logs/test.log")

logger.info "Hello World"
# Logs to both $stdout and logs/test.log
# [test] [INFO] [2022-11-17 11:46:12 +0100] Hello World
```

### Block-based configuration

For more control, configure all backends in a block:

```ruby
logger = Dry.Logger(:test) do |setup|
  setup.add_backend(stream: "logs/test.log", template: :details)
  setup.add_backend(stream: "logs/errors.log", log_if: :error?)
end

logger.info "Hello World"
# Only logs to the files you configured (no stdout)
```

When you use a block, dry-logger skips creating the default stdout backend, giving you complete control.

### Conditional logging

Route logs to specific backends based on conditions using `log_if`:

```ruby
logger = Dry.Logger(:test, template: :details)
  .add_backend(stream: "logs/requests.log", log_if: -> entry { entry.key?(:request) })

logger.info "Hello World"
# Only to $stdout: [test] [INFO] [2022-11-17 11:50:12 +0100] Hello World

logger.info "GET /posts", request: true
# To both $stdout and logs/requests.log
# [test] [INFO] [2022-11-17 11:51:50 +0100] GET /posts request=true
```

## Templates and formatting

### Custom templates

Customize the log format using sprintf-style templates:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] %<message>s")

logger.info "Hello World"
# [INFO] Hello World
```

The following tokens are supported:

- `%<progname>s` - Logger identifier
- `%<severity>s` - Log level (DEBUG, INFO, WARN, ERROR, FATAL)
- `%<time>s` - Timestamp
- `%<message>s` - Log message
- `%<payload>s` - Structured data as key=value pairs

You can also use payload keys directly in templates:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] %<verb>s %<path>s")

logger.info verb: "GET", path: "/users"
# [INFO] GET /users
```

### Colorized output

Use color tags in templates for better readability:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] <blue>%<verb>s</blue> <green>%<path>s</green>")

logger.info verb: "GET", path: "/users"
# [INFO] GET /users (with blue verb and green path)
```

Available colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `gray`

### Formatters

dry-logger includes three formatters:

- `:string` - Human-readable `key=value` format with color support (development)
- `:json` - Structured JSON with UTC timestamps (production)
- `:rack` - Optimized for HTTP request logging

Use the `formatter` option:

```ruby
logger = Dry.Logger(:test, formatter: :rack)

logger.info verb: "GET", path: "/users", elapsed: "12ms", ip: "127.0.0.1", status: 200, length: 312, params: {}
# [test] [INFO] [2022-11-17 12:04:30 +0100] GET 200 12ms 127.0.0.1 /users 312
```

## Log rotation

Rotate logs by size or time period:

**Size-based rotation:**

```ruby
# Keep 5 files, max 10MB each
logger = Dry.Logger(:test,
  stream: "logs/test.log",
  shift_age: 5,
  shift_size: 10_485_760
)
```

**Time-based rotation:**

```ruby
# Rotate daily, weekly, or monthly
logger = Dry.Logger(:test, stream: "logs/test.log", shift_age: "daily")
```

See Ruby's [Logger documentation](https://rubyapi.org/o/logger#class-Logger-label-Log+File+Rotation) for details.

## Next steps

Now that you understand the basics, explore more features:

- [Backends](/gems/dry-logger/backends/) - Configure multiple logging destinations
- [Formatters](/gems/dry-logger/formatters/) - Control output format (string, JSON, Rack)
- [Templates](/gems/dry-logger/templates/) - Customize log message format
- [Filtering](/gems/dry-logger/filtering/) - Filter sensitive data from logs
- [Context](/gems/dry-logger/context/) - Add request-scoped data to log entries
- [Tagged logging](/gems/dry-logger/tagging/) - Mark and filter log entries with tags
- [Crash handling](/gems/dry-logger/crash-handling/) - Customize behavior when logging itself crashes
- [Testing](/gems/dry-logger/testing/) - Test your application's logging
- [Examples](/gems/dry-logger/examples/) - Complete, realistic configuration examples
