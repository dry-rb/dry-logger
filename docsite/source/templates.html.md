---
title: Templates
layout: gem-single
name: dry-logger
---

Templates control the layout and content of text-based log output. They work with the string and rack formatters to determine which fields appear in the output and how they're arranged.

## Understanding templates

Templates use Ruby's `sprintf`-style format strings with named placeholders. Each placeholder corresponds to a field in the log entry.

```ruby
logger = Dry.Logger(:my_app,
  template: "[%<severity>s] %<message>s"
)

logger.info("Server started")
# [INFO] Server started
```

## Built-in templates

### Default template

The simplest template, showing just the message and payload:

```ruby
logger = Dry.Logger(:my_app, template: :default)
# Equivalent to: "%<message>s %<payload>s"

logger.info("Hello", name: "World")
# Hello name="World"
```

### Details template

A comprehensive template showing progname, severity, timestamp, message, and payload:

```ruby
logger = Dry.Logger(:my_app, template: :details)
# Equivalent to: "[%<progname>s] [%<severity>s] [%<time>s] %<message>s %<payload>s"

logger.info("Server started", port: 3000)
# [my_app] [INFO] [2023-10-15 14:30:00 +0000] Server started port=3000
```

This is ideal for production file logs where you need full context for each entry.

## Standard template tokens

These tokens are available in all log entries:

### Meta tokens

- `%<progname>s` - Logger identifier (set when creating the logger)
- `%<severity>s` - Log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)
- `%<time>s` - Timestamp of the log entry
- `%<message>s` - The log message (if provided)
- `%<payload>s` - Key-value pairs from the payload

### Example using all meta tokens

```ruby
logger = Dry.Logger(:my_app,
  template: "%<time>s [%<progname>s] %<severity>s: %<message>s %<payload>s"
)

logger.warn("High memory usage", used_mb: 1024, available_mb: 512)
# 2023-10-15 14:32:00 +0000 [my_app] WARN: High memory usage used_mb=1024 available_mb=512
```

## Custom templates

Create your own templates for specific needs:

### Minimal template

```ruby
logger = Dry.Logger(:my_app,
  template: "%<message>s"
)

logger.info("Simple message")
# Simple message
```

### Timestamp-first template

```ruby
logger = Dry.Logger(:my_app,
  template: "%<time>s | %<severity>s | %<message>s %<payload>s"
)

logger.error("Connection failed", host: "db.example.com")
# 2023-10-15 14:35:12 +0000 | ERROR | Connection failed host="db.example.com"
```

### Application-focused template

```ruby
logger = Dry.Logger(:my_app,
  template: "[%<progname>s] %<message>s %<payload>s"
)

logger.info("User action", action: "login", user_id: 42)
# [my_app] User action action="login" user_id=42
```

## Payload-based templates

You can include specific payload keys directly in your template. This is useful when you know certain fields will always be present:

```ruby
logger = Dry.Logger(:api,
  template: "[%<severity>s] %<verb>s %<path>s - %<status>s"
)

logger.info(verb: "GET", path: "/users/42", status: 200)
# [INFO] GET /users/42 - 200
```

When using payload keys in templates:

- The specified keys are extracted from the payload and formatted individually
- Remaining payload keys are formatted as `key=value` pairs in `%<payload>s`

```ruby
logger = Dry.Logger(:api,
  template: "%<verb>s %<path>s | %<payload>s"
)

logger.info(verb: "POST", path: "/users", status: 201, user_id: 42)
# POST /users | status=201 user_id=42
# (verb and path were used in template, so only status and user_id appear in payload)
```

## Colorized templates

Add color to your log output using color tags. This is especially useful for development environments:

```ruby
logger = Dry.Logger(:my_app,
  template: "[<blue>%<severity>s</blue>] <green>%<message>s</green>"
)

logger.info("Server started")
# [INFO] Server started
# (with INFO in blue and message in green)
```

### Available colors

- `<black>...</black>`
- `<red>...</red>`
- `<green>...</green>`
- `<yellow>...</yellow>`
- `<blue>...</blue>`
- `<magenta>...</magenta>`
- `<cyan>...</cyan>`
- `<gray>...</gray>`

### Colorized example

```ruby
logger = Dry.Logger(:my_app,
  template: "[<cyan>%<progname>s</cyan>] [<yellow>%<severity>s</yellow>] %<message>s"
)

logger.warn("Memory warning", usage: "85%")
# [my_app] [WARN] Memory warning usage="85%"
# (with colored progname and severity)
```

## Registering custom templates

For templates you use frequently, register them globally:

```ruby
Dry::Logger.register_template(
  :my_template,
  "[%<severity>s] %<time>s - %<message>s"
)

logger = Dry.Logger(:my_app, template: :my_template)

logger.info("Using custom template")
# [INFO] 2023-10-15 14:40:00 +0000 - Using custom template
```

### Registering colorized templates

```ruby
Dry::Logger.register_template(
  :dev,
  "<cyan>[%<progname>s]</cyan> <yellow>[%<severity>s]</yellow> %<message>s %<payload>s"
)

logger = Dry.Logger(:my_app, template: :dev)
```

## Per-backend templates

Different backends can use different templates:

```ruby
logger = Dry.Logger(:my_app) do |setup|
  # Colorized, detailed output for console
  setup.add_backend(
    stream: $stdout,
    template: "<cyan>[%<progname>s]</cyan> <yellow>%<severity>s</yellow> %<message>s %<payload>s"
  )

  # Plain detailed output for file
  setup.add_backend(
    stream: "logs/app.log",
    template: :details
  )

  # Minimal output for errors file
  setup.add_backend(
    stream: "logs/errors.log",
    template: "%<time>s %<message>s %<payload>s",
    log_if: :error?
  )
end
```

## Special templates

### Rack template

The rack formatter has its own specialized template for HTTP requests:

```ruby
# Automatically used by formatter: :rack
"[%<progname>s] [%<severity>s] [%<time>s] " \
"%<verb>s %<status>s %<elapsed>s %<ip>s %<path>s %<length>s %<payload>s\n" \
"  %<params>s"
```

### Crash template

Used internally when logging itself crashes:

```ruby
"[%<progname>s] [%<severity>s] [%<time>s] Logging crashed\n" \
"  %<log_entry>s\n" \
"  %<message>s (%<exception>s)\n" \
"%<backtrace>s"
```

For complete, realistic configuration examples, see the [Examples](docs::examples) page.

## Tags in templates

If you use tagged logging, include the `%<tags>s` token:

```ruby
logger = Dry.Logger(:my_app,
  template: "[%<tags>s] %<message>s %<payload>s"
)

logger.tagged(:production, :web) do
  logger.info("Request received", path: "/")
end
# [production web] Request received path="/"
```

Learn more about tagging in the [Tagging guide](docs::tagging).

## Best practices

### Choose templates based on output destination

- **Console (development)**: Use colorized templates for easy scanning
- **Files (production)**: Use `:details` template for complete information
- **JSON logs**: Templates don't apply (formatter handles structure)

### Keep templates consistent

For team projects, register standard templates:

```ruby
# config/logger_templates.rb
Dry::Logger.register_template(:app_default, :details)
Dry::Logger.register_template(:app_console, "<cyan>[%<severity>s]</cyan> %<message>s")
Dry::Logger.register_template(:app_api, "%<verb>s %<path>s %<status>s %<elapsed>s")
```

### Use payload keys for structured data

When you have consistent structured data, use payload keys in templates:

```ruby
# Instead of this:
template: "%<message>s %<payload>s"

# Use this when you always log certain fields:
template: "%<message>s | User: %<user_id>s | Action: %<action>s"
```

This makes logs easier to parse visually and with tools.

For complete configuration examples showing templates in action, see the [Examples](docs::examples) page.
