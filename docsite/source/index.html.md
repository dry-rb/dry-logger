---
title: Introduction
layout: gem-single
name: dry-logger
type: gem
---

dry-logger provides a standalone, dependency-free logging solution suitable for any Ruby application.

- Structured logging *by default*
- Logging to multiple destinations via pluggable logging `backends`
- Fine-grained log formatting using `formatters`
- Customizable logging logic via log filtering
- Out-of-the-box exception logging
- Built-in support for text log templates with customizable colorized output
- Built-in support for tagged log entries
- Public API for adding your own `backends` and `formatters`

### Basic setup

To configure a basic `$stdout` logger simply use the main setup method `Dry.Logger`:

```ruby
logger = Dry.Logger(:my_app)

logger.info "Hello World"
# Hello World
```

The setup method accepts various options to configure the logger. You can change default formatter,
provide customized text templates, and so on.

Let's use a more detailed logging template that gives more logging context in the output:

```ruby
logger = Dry.Logger(:test, template: :details)

logger.info "Hello World"
# [test] [INFO] [2022-11-17 11:43:52 +0100] Hello World

logger.info { "Hello World from a block" }
# [test] [INFO] [2022-11-17 11:44:12 +0100] Hello World from a block
```

### Using multiple logging destinations

You can configure your logger to log to more than one destination. In case of the default logger,
the destination is set to `$stdout`. Let's say you want to log both to `$stdout` and a file:

```ruby
logger = Dry.Logger(:test, template: :details).add_backend(stream: "logs/test.log")

# This goes to $stdout and logs/test.log too
logger.info "Hello World"
# [test] [INFO] [2022-11-17 11:46:12 +0100] Hello World
```

### Skipping default behaviour

If you don't want to log to the default `$stdout` you can skip it by passing in a block to the
constructor:

```ruby
logger = Dry.Logger(:test) do |dispatcher|
  dispatcher.add_backend(stream: "logs/test.log", template: :details)
end

# This goes to logs/test.log
logger.info "Hello World"
# [test] [INFO] [2022-11-17 11:46:12 +0100] Hello World
```

### Conditional logging

You can tell your backends when exactly they should be logging using `log_if` option. It can be set
to either a symbol that represents a method that `Dry::Logger::Entry` implements or a custom proc.

Here's a simple example:

```ruby
logger = Dry.Logger(:test, template: :details)
  .add_backend(stream: "logs/requests.log", log_if: -> entry { entry.key?(:request) })

# This goes only to $stdout
logger.info "Hello World"
# [test] [INFO] [2022-11-17 11:50:12 +0100] Hello World

# This goes to $stdout and logs/requests.log
logger.info "GET /posts", request: true
# [test] [INFO] [2022-11-17 11:51:50 +0100] GET /posts request=true
```

### Using custom templates

You can provide customized text log templates using regular Ruby syntax for tokenized string templates:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] %<message>s")

logger.info "Hello World"
# [INFO] Hello World
```

The following tokens are supported:

- `%<progname>s` - the name of your logger, ie `Dry.Logger(:test)` sets `progname` to `test`
- `%<severity>s` - log level name
- `%<time>s` - log entry timestamp
- `%<message>s` - log text message passed as a string, ie `logger.info("Hello World")` sets `message` to `"Hello World"`
- `%<payload>s` - optional log entry payload provided as keywords, ie `logger.info(text: "Hello World")` sets `payload` to `{text: "Hello World"}` and its presentation depends on the formatter that was used

Furthermore, you can use *payload keys* that are expected to be passed to a specific logging backend.
Here's an example:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] %<verb>s %<path>s")

logger.info verb: "GET", path: "/users"
# [INFO] GET /users
```

### Using colorized text output

You can use simple color tags to colorize specific values in the text output:

```ruby
logger = Dry.Logger(:test, template: "[%<severity>s] <blue>%<verb>s</blue> <green>%<path>s</green>")

# This is now colorized, you gotta trust us
logger.info verb: "GET", path: "/users"
# [INFO] GET /users
```

Following built-in color tags are supported:

- black
- red
- green
- yellow
- blue
- magenta
- cyan
- gray

### Customizing formatters

There are three built-in formatters:

- `:string` - formats payload into `key=value` sequence and supports colorized output, suitable for development environmments
- `:json` - suitable for production environments, formats timestamps into `UTC`
- `:rack` - suitable for logging rack requests

To configure a specific formatter, use the `formatter` option:

```ruby
logger = Dry.Logger(:test, formatter: :rack)

logger.info verb: "GET", path: "/users", elapsed: "12ms", ip: "127.0.0.1", status: 200, length: 312, params: {}
# [test] [INFO] [2022-11-17 12:04:30 +0100] GET 200 12ms 127.0.0.1 /users 312
```

### Configuring log rotation

You can use the Ruby Logger's [log rotation support](https://rubyapi.org/o/logger#class-Logger-label-Log+File+Rotation) for any stream-based logger backend.

To rotate log files based on size, provide:

- `shift_age:` as a positive integer: the number of log files to be in the rotation.
- `shift_size:` as a positive integer: the maximum size (in bytes) of each log file; defaults to 1048576 (1 megabyte).

```ruby
# Five 10-megabyte files.
logger = Dry.logger(:test, stream: "logs/test.log", shift_age: 5, shift_size: 10485760)
```

To rotate log files based on age, provide:

- `shift_age:` as a string period indicator (`"daily"`, `"weekly"`, `"monthly"`)

```ruby
logger = Dry.logger(:test, stream: "logs/test.log", shift_age: "daily")
```

See the [Ruby Logger documentation]((https://rubyapi.org/o/logger#class-Logger-label-Log+File+Rotation)) for more detail on its log rotation support.
