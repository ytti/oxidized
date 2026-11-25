# Deprecations
This page lists features, configuration options, models and platforms that are
deprecated in Oxidized and will be removed in a future release.

Deprecated features still work, but most of them log a warning when used.
Please migrate to the replacement before the planned removal.

| Deprecated                                    | Since      | Planned removal | Replacement                                            |
|-----------------------------------------------|------------|-----------------|--------------------------------------------------------|
| [Ruby 3.0 and Ruby 3.1](#ruby-30-and-ruby-31) | unreleased | June 2028       | Ruby >= 3.2                                            |
| [Configuration `rest`](#configuration-rest)   | 0.33.0     | April 2027      | `extensions.oxidized-web`                              |
| [Configuration `log` and `use_syslog`](#configuration-log-and-use_syslog)    | 0.34.0 | April 2027 | `logger`                         |
| [Model `apc_aos`](#model-apc_aos)             | 0.36.0     | April 2027      | Model `ApcAos`                                         |
| [Fortigate variable `fortios_autoupdate`](#fortigate-variable-fortios_autoupdate) | 0.36.0 | not scheduled | Variable `fortigate_autoupdate` |
| [Model `supermicro`](#model-supermicro)       | 0.22.0     | December 2026   | Model `edgecos`                                        |

## Ruby 3.0 and Ruby 3.1
Ruby 3.0 and 3.1 have reached their end of life (3.0 in April 2024, 3.1 in
March 2025) and no longer receive security fixes. Please upgrade to Ruby 3.2 or
newer.

Support for Ruby 3.0 and 3.1 is planned to be removed in June 2028, when
Debian LTS for Debian 12 ends. By then, none of the LTS distributions below
is supported any more without paid extended support.

### LTS distributions without Ruby >= 3.2
Oxidized tries to support the Ruby versions of the LTS releases of common
Linux distributions. These still ship Ruby 3.0 or 3.1 as their system Ruby
(as of November 2026):

| Distribution      | System Ruby | End of support            | Extended support |
|-------------------|-------------|---------------------------|------------------|
| Ubuntu 22.04 LTS  | 3.0         | June 2027 (standard)      | April 2032 (ESM) |
| Debian 12         | 3.1         | June 2028 (Debian LTS)    | June 2033 (ELTS) |
| RHEL 9 and clones | 3.0         | May 2027 (full support)   | May 2032         |

Notes:
- Ubuntu 24.04 (Ruby 3.2), Ubuntu 26.04 and Debian 13 (Ruby 3.3) are not
  affected.
- RHEL 8 and 9 provide newer Ruby versions as AppStream module streams
  (e.g. `ruby:3.3`), so they can run Ruby >= 3.2 without the system Ruby.
- On any distribution, a newer Ruby can be installed with a Ruby version
  manager (rbenv, ruby-install, ...) or Oxidized can be run from the
  [docker image](Docker.md).

### Removal must be coordinated with oxidized-web
Raising `required_ruby_version` in Oxidized must be coordinated with
[oxidized-web](https://github.com/ytti/oxidized-web):
- oxidized-web depends on oxidized, and oxidized has oxidized-web as a
  development dependency. Both CIs install the other gem and test the
  same Ruby versions (3.0 and 3.1 on `ubuntu-24.04`, 3.2 and newer on
  `ubuntu-latest`).
- If only one of them drops Ruby 3.0 and 3.1, the CI of the other one
  breaks on those versions, or bundler silently resolves an older release
  of the gem that still supports them, so the tests no longer run against
  the current code.
- Both gems should therefore raise `required_ruby_version` and remove
  Ruby 3.0 and 3.1 from `.github/workflows/ruby.yml` in releases that are
  published together.

## Configuration `rest`
The old syntax `rest: 127.0.0.1:8888/prefix` to configure oxidized-web has been
replaced by `extensions.oxidized-web`, which needs oxidized-web 0.16.0 or later.
When `rest` is configured, Oxidized logs a warning and ignores
`extensions.oxidized-web`.

See [Configuration](Configuration.md#oxidized-web-restful-api-and-web-interface).

## Configuration `log` and `use_syslog`
Oxidized 0.34.0 introduced a new logging system based on
[Semantic Logger](https://logger.rocketjob.io/). The old configuration options
`log` and `use_syslog` still work but log a warning. Remove them and configure
the `logger` section instead.

See [Logging](Configuration.md#logging).

## Model `apc_aos`
The old model `apc_aos` only supports SCP and FTP. It has been replaced by the
model `ApcAos`, which also supports SSH. Change the model of your nodes from
`apc_aos` to `apcaos`.

See [APC Model Notes](Model-Notes/APC.md).

## Fortigate variable `fortios_autoupdate`
The variable `fortios_autoupdate` of the model `fortigate` has been renamed to
`fortigate_autoupdate`.

See [Fortinet Model Notes](Model-Notes/Fortinet.md#autoupdate).

## Model `supermicro`
The model `supermicro` is a backward compatibility shim for the model
`edgecos`. Change the model of your nodes from `supermicro` to `edgecos`.
