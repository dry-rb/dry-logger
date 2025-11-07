---
title: Crash handling
layout: gem-single
name: dry-logger
---

By default, if logging itself crashes, dry-logger handles the error gracefully and logs to stderr. You can customize this behavior.

## Default crash behavior

```ruby
logger = Dry.Logger(:my_app)

# If logging crashes, you'll see something like:
# [my_app] [FATAL] [2023-10-15 14:00:00 +0000] Logging crashed
#   Original message
#   Error details (ExceptionClass)
#   Backtrace...
```

## Custom crash handler

```ruby
logger = Dry.Logger(:my_app,
  on_crash: -> (progname:, exception:, message:, payload:) {
    # Send to error tracking service
    Sentry.capture_exception(exception,
      extra: {
        progname: progname,
        log_message: message,
        log_payload: payload
      }
    )

    # Also write to a separate crash log
    File.open("logs/logging_crashes.log", "a") do |f|
      f.puts "Logging crashed: #{exception.message}"
      f.puts "Progname: #{progname}"
      f.puts "Message: #{message.inspect}"
      f.puts "Payload: #{payload.inspect}"
    end
  }
)
```

## Crash prevention

Ensure your crash handler doesn't itself crash:

```ruby
on_crash: -> (progname:, exception:, **) {
  begin
    # Try to send to monitoring service
    ErrorTracker.notify(exception, context: progname)
  rescue => error
    # Fallback: write to stderr
    warn "Logging crashed AND crash handler failed: #{error.message}"
    warn "Original error: #{exception.message}"
  end
}
```
