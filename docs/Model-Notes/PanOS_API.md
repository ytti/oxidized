# PanOS API

Backup Palo Alto XML configuration via the HTTP API. Works for PanOS and Panorama.

Logs in using username and password and fetches an API key.

## Requirements

- Create a user with a `Superuser (read-only)` admin role in Panorama or PanOS.
  A custom admin role needs the XML API permission `Operational Requests`
  (or `Export` when using `panos_api_candidate`).
- Make sure the `nokogiri` gem is installed with your oxidized host

## Running vs. candidate configuration

The model backs up the running configuration (`show config running`), so
uncommitted changes are not included.

Previous versions of the model backed up the candidate configuration,
including uncommitted changes (see
[#2759](https://github.com/ytti/oxidized/issues/2759)). To keep this behaviour,
set the variable `panos_api_candidate` to `true`:

```yaml
models:
  panos_api:
    vars:
      panos_api_candidate: true
```

## Configuration

Make sure the following is configured in the oxidized config:

```yaml
# allow ssl host name verification
resolve_dns: false
input:
  default: ssh, http
  http:
    secure: true
    ssl_verify: true

# model specific configuration
#model:
#  panos_api:
```
