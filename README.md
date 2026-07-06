<!--- This file is synced from hanakai-rb/repo-sync -->

[actions]: https://github.com/dry-rb/dry-logger/actions
[chat]: https://discord.gg/naQApPAsZB
[forum]: https://discourse.hanamirb.org
[rubygem]: https://rubygems.org/gems/dry-logger

# dry-logger [![Gem Version](https://badge.fury.io/rb/dry-logger.svg)][rubygem] [![CI Status](https://github.com/dry-rb/dry-logger/workflows/CI/badge.svg)][actions]

This is a fork of the original **dry-logger** that supports fiber-safe isolation. The main difference is that child fibers inherit the parent context, with copy-on-write semantics for any modifications.

## Links

- [User documentation](https://dry-rb.org/gems/dry-logger)
- [API documentation](http://rubydoc.info/gems/dry-logger)
- [Forum](https://discourse.dry-rb.org)

## License

See `LICENSE` file.
