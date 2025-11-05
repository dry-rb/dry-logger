# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

## [1.2.0] - 2025-11-05

### Changed

- When a block is given when logging, do not execute the block if the severity is lower than the configured logger level. (@p8 in #33)
- When a block is given when logging, and that block returns a hash, use that hash as the log payload. (@p8 in #34)

## [1.1.0] - 2025-04-17

### Added

- Support `::Logger`'s log rotation in stream-based logger backends, via `shift_size:` and `shift_age:` arguments (@wuarmin in #31)

## [1.0.4] - 2024-05-10

### Fixed

- Accept log messages via given block, ensuring compatibility with standard Ruby logger (via #28) (@komidore64)

### Changed

- Drop support for Ruby 2.7 (via #29) (@timriley)

## [1.0.3] - 2022-12-09

### Added

- Support for ruby 2.7 (needs backports gem that *you* need to add to your Gemfile) (via #24) (@solnic)

## [1.0.2] - 2022-11-24

### Fixed

- Handle `:log_if` in Proxy constructors (via #23) (@solnic)

## [1.0.1] - 2022-11-23

### Fixed

- Support for `log_if` in proxied loggers (via 81115320b490034ddf9dfe4f3775322b9271e0cd) (@solnic)
- Support exceptions and payloads in proxied loggers (via 93b3fd59ebbdc7e63620eb064694d58455df831f) (@solnic)

## [1.0.0] - 2022-11-17

This is a port of the original Hanami logger from hanami-utils extended with support for logging
dispatchers that can log to different destinations and plenty more.

### Added

- Support arbitrary logging backends through proxy (via #12) (@solnic)
- Support for conditional logging when using arbitrary logging backends (via #13) (@solnic)
- Support for registering templates via `Dry::Logger.register_template` (via #14) (@solnic)
- Support for payload keys as template tokens (via #14) (@solnic)
- Support for payload value formatter methods, ie if there's `:verb` token your formatter can implement `format_verb(value)` (via #14) (@solnic)
- Support block-based setup (via #16) (@solnic)
- Support for defining cherry-picked keys from the payload in string templates (via #17) (@solnic)
- Support for `%<payload>s` template token. It will be replaced by a formatted payload, excluding any key that you specified explicitly in the template (via #17) (@solnic)
- Support for colorized output using color tags in templates (via #18) (@solnic)
- Support for `colorize: true` logger option which enables severity coloring in string formatter (via #18) (@solnic)
- `:details` template: `"[%<progname>s] [%<severity>s] [%<time>s] %<message>s %<payload>s"` (@solnic)
- A new option `on_crash` for setting up a logger-crash handling proc (via #21) (@solnic)
- Handle logger crashes by default using a simple `$stdout` logger (via #21) (@solnic)
- Support for regular logger backends that don't support `log?` predicate (@solnic)
- Support for providing a string template for log entries via `template` option (via #7) (@solnic)
- `:rack` string log formatter which inlines request info and displays params at the end (@solnic)
- Conditional log dispatch via `#log_if` backend's predicate (via #9) (@solnic)
- Add support for shared context and tagged log entries (via #10) (@solnic)

[1.2.0]: https://github.com/dry-rb/dry-logger/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/dry-rb/dry-logger/compare/v1.0.4...v1.1.0
[1.0.4]: https://github.com/dry-rb/dry-logger/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/dry-rb/dry-logger/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/dry-rb/dry-logger/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/dry-rb/dry-logger/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dry-rb/dry-logger/releases/tag/v1.0.0
