# PanOS API

Backup Palo Alto XML configuration via the HTTP API. Works for PanOS and Panorama.

Logs in using username and password and fetches an API key.

## Requirements

- Create a user with a `Superuser (read-only)` admin role in Panorama or PanOS
- Make sure the `nokogiri` gem is installed with your oxidized host

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
