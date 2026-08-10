# Changelog

All notable changes to CobbleBot are documented in this file.

The project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.58.1] - 2026-08-09

### Added

- Added a supported Ruby 3.3.12 and Rails 8.1.3.1 runtime with Rails 8.1
  configuration defaults.
- Added GitHub Actions coverage for PostgreSQL, Redis, the complete parallel
  test suite, concurrency diagnostics, and a 75% serial coverage gate.
- Added supervisor-neutral worker bootstrap and queue reconciliation tasks for
  the watchdog, Minecraft log monitor, and optional IRC worker.
- Added local Rouge callback highlighting and vendored legacy web assets so
  runtime rendering no longer depends on retired external asset services.

### Changed

- Upgraded the Redis and worker stack to redis-rb 6 with RESP3, Resque 3,
  Resque Scheduler 5, and Redis Namespace 1.11.
- Upgraded the application server, database adapters, Haml renderer, browser
  test stack, coverage tooling, and remaining supported dependencies.
- Reworked Minecraft log monitoring to handle truncation and rotation without
  replaying historical commands.
- Updated installation, deployment, worker lifecycle, testing, and rollback
  documentation for the supported runtime.
- Changed callback command execution and other state-changing admin actions to
  use appropriate non-GET request methods.

### Fixed

- Fixed legacy migrations so fresh databases migrate cleanly on modern Rails.
- Restored `minecraft-query` timeout behavior on Ruby 3 and isolated query
  tests from the live default Minecraft port.
- Bounded RCON response draining and normalized commands before execution.
- Made managed Resque reservation and reconciliation atomic to avoid duplicate
  watchdog, log-monitor, and IRC jobs during concurrent maintenance.
- Serialized matching callback execution across cooldown windows and improved
  error handling around callbacks, worker maintenance, and external services.
- Fixed callback highlighting, Haml rendering compatibility, pagination,
  production assets, and CobbleBot version-link output.
- Added uniqueness migrations and model safeguards for mute, IP, and reputation
  pairs, retaining one record from each pre-existing duplicate pair.

### Security

- Removed the default administrator password and require an explicit
  `COBBLEBOT_WEB_ADMIN_PASSWORD` when seeding a new database.
- Require server-authenticated IRC identities for privileged commands instead
  of trusting nicknames.
- Hardened request methods, frontend interpolation, link handling, parameter
  filtering, and concurrent command execution boundaries.

### Removed

- Removed the retired Slack and Google Translate integrations and their stored
  preferences and callbacks.
- Removed obsolete API session endpoints, the admin console endpoint, remote
  Pygments highlighting, Rack Mini Profiler wiring, and legacy supervisor
  configuration.
- Removed unsupported Rails 4-era dependency paths and the Travis CI workflow.
