---
title: Formatters
layout: gem-single
name: dry-logger
---

Formatters control how log entries are serialized for output. dry-logger includes three built-in formatters optimized for different use cases.

## Built-in formatters

### String formatter (default)

The `:string` formatter outputs human-readable text in `key=value` format. It's ideal for development and when you need to read logs directly.

```ruby
logger = Dry.Logger(:my_app, formatter: :string)

logger.info("User logged in", user_id: 42, role: "admin")
# User logged in user_id=42 role="admin"
```

The string formatter:

- Formats payloads as `key=value` pairs
- Quotes string values
- Supports colorized output
- Handles exceptions with full backtraces
- Works with templates for customization

### JSON formatter

The `:json` formatter outputs structured JSON, perfect for production environments and log aggregation tools.

```ruby
logger = Dry.Logger(:my_app, formatter: :json)

logger.info("User logged in", user_id: 42, role: "admin")
# {"progname":"my_app","severity":"INFO","time":"2023-10-15T14:23:45Z","message":"User logged in","user_id":42,"role":"admin"}
```

The JSON formatter:

- Outputs valid JSON on each line
- Converts timestamps to UTC ISO8601 format
- Flattens exception data into the JSON structure
- Perfect for tools like Elasticsearch, Splunk, or CloudWatch

Example with exception:

```ruby
begin
  raise ArgumentError, "Invalid input"
rescue => e
  logger.error(e)
end
# {"progname":"my_app","severity":"ERROR","time":"2023-10-15T14:24:12Z","exception":"ArgumentError","message":"Invalid input","backtrace":["..."]}
```

### Rack formatter

The `:rack` formatter is specialized for logging HTTP requests in web applications.

```ruby
logger = Dry.Logger(:my_app, formatter: :rack)

logger.info(
  verb: "GET",
  path: "/users/42",
  status: 200,
  elapsed: "12ms",
  ip: "192.168.1.1",
  length: 1024,
  params: {page: 1}
)
# [my_app] [INFO] [2023-10-15 14:25:30 +0000] GET 200 12ms 192.168.1.1 /users/42 1024
#   {"page":1}
```

The rack formatter uses a predefined template that formats common HTTP request fields in a compact, readable format.

## Per-backend formatters

Different backends can use different formatters:

```ruby
logger = Dry.Logger(:my_app) do |setup|
  # Human-readable logs to stdout for development
  setup.add_backend(
    stream: $stdout,
    formatter: :string,
    template: :details
  )

  # JSON logs to file for production analysis
  setup.add_backend(
    stream: "logs/app.json",
    formatter: :json
  )

  # Rack-formatted HTTP logs
  setup.add_backend(
    stream: "logs/requests.log",
    formatter: :rack,
    log_if: -> (entry) { entry.key?(:verb) }
  )
end

# Now this logs to all three backends in different formats
logger.info("Starting server", port: 3000)
```

## Formatter options

### String formatter options

The string formatter supports several customization options:

#### Templates

Control the output format using templates (see [Templates](/gems/dry-logger/templates/) for details):

```ruby
logger = Dry.Logger(:my_app,
  formatter: :string,
  template: "[%<severity>s] %<time>s - %<message>s %<payload>s"
)

logger.info("Server started", port: 3000)
# [INFO] 2023-10-15 14:30:00 +0000 - Server started port=3000
```

#### Colorization

Enable colorized output for better readability in terminals:

```ruby
logger = Dry.Logger(:my_app,
  formatter: :string,
  colorize: true
)

logger.debug("Debug message")  # Cyan
logger.info("Info message")    # Magenta
logger.warn("Warning")         # Yellow
logger.error("Error")          # Red
logger.fatal("Fatal error")    # Red
```

#### Custom severity colors

Customize which colors are used for each severity level:

```ruby
logger = Dry.Logger(:my_app,
  formatter: :string,
  colorize: true,
  severity_colors: {
    debug: :gray,
    info: :green,
    warn: :yellow,
    error: :red,
    fatal: :magenta
  }
)
```

Available colors:

- `:black`
- `:red`
- `:green`
- `:yellow`
- `:blue`
- `:magenta`
- `:cyan`
- `:gray`

### JSON formatter options

The JSON formatter automatically:

- Converts all timestamps to UTC
- Formats timestamps as ISO8601 strings
- Includes all metadata (progname, severity, time)
- Merges payload data into the root object

No additional configuration is needed for the JSON formatter.

## Exception formatting

### String formatter

Exceptions are formatted with full details:

```ruby
logger = Dry.Logger(:my_app, formatter: :string, template: :details)

begin
  File.read("missing.txt")
rescue => e
  logger.error(e)
end

# [my_app] [ERROR] [2023-10-15 14:35:12 +0000]
#   No such file or directory @ rb_sysopen - missing.txt (Errno::ENOENT)
#   /path/to/file.rb:10:in `read'
#   /path/to/file.rb:10:in `<main>'
```

### JSON formatter

Exceptions are serialized as JSON fields:

```ruby
logger = Dry.Logger(:my_app, formatter: :json)

begin
  File.read("missing.txt")
rescue => e
  logger.error(e)
end

# {"progname":"my_app","severity":"ERROR","time":"2023-10-15T14:35:12Z","exception":"Errno::ENOENT","message":"No such file or directory @ rb_sysopen - missing.txt","backtrace":["..."]}
```

## Custom formatters

Create formatters for specialized output needs.

### Simple custom formatter

```ruby
class CustomFormatter
  def call(_severity, _time, _progname, entry)
    # Must return a string
    "#{entry.severity} | #{entry.message} | #{entry.payload.inspect}\n"
  end
end

logger = Dry.Logger(:my_app, formatter: CustomFormatter.new)

logger.info("Test", user_id: 42)
# INFO | Test | {:user_id=>42}
```

### Extending built-in formatters

```ruby
class MyFormatter < Dry::Logger::Formatters::String
  private

  # Customize how specific fields are formatted
  def format_user_id(value)
    "USER:#{value}"
  end

  def format_duration(value)
    "#{value}ms"
  end
end

# Register your formatter
Dry::Logger.register_formatter(:my_formatter, MyFormatter)

logger = Dry.Logger(:my_app,
  formatter: :my_formatter,
  template: "%<user_id>s took %<duration>s"
)

logger.info(user_id: 42, duration: 150)
# USER:42 took 150ms
```

For complete, realistic configuration examples, see the [Examples](/gems/dry-logger/examples/) page.
