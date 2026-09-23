# Cisco FTD via HTTP

Back up Cisco FTD firewalls via the [HTTP API](https://www.cisco.com/c/en/us/td/docs/security/firepower/ftd-api/guide/ftd-rest-api/ftd-rest-api-intro.html). This model uses the [configexport](https://www.cisco.com/c/en/us/td/docs/security/firepower/ftd-api/guide/ftd-rest-api/ftd-api-import-export.html#id_108006) method to export the configuration as a zip file, then extracts the JSON configuration from this file.

## Configuration

Ensure that the HTTP input is enabled in the Oxidized configuration, e.g.:

```yaml
input:
  default: ssh, http
```

Oxidized will need to use the FTD's admin login. Set the username at the model level:

```yaml
models:
  ftd:
    username: admin
```

When integrating with LibreNMS, you may need to override the IP address used by Oxidized (e.g. if SNMP and the HTTP API are listening on different interfaces on your FTD). This can be done with a mapping rule, e.g.:

```shell
lnms config:set oxidized.maps.ip.hostname.+ '{"match": "HOSTNAME", "value": "IP"}'
```

(Where `HOSTNAME` is the hosname/IP address used when adding the device to LibreNMS, and `IP` is the IP address for the HTTP API.)

The port for the HTTP API can be overridden with a variable. For example, create a mapping rule to assign the device to a group, e.g.:

```shell
lnms config:set oxidized.maps.group.hostname.+ '{"match": "HOSTNAME", "value": "GROUP"}'
```

(Where `HOSTNAME` is the hosname/IP address used when adding the device to LibreNMS, and `GROUP` is an appropriate group name.)

Then set the port variable at the group level. You can also override the password here if necessary, e.g.:

```yaml
groups:
  GROUP:
    vars:
      ftd_api_port: 8443
    password: secret
```

## Variables

The following variables can be used to control the behaviour of the model:

- ftd\_api\_endpoint: URL path to the FTD API (default: /api/fdm/latest)
- ftd\_api\_port: HTTPS port for the FTD API (default: 443)
- ftd\_config\_filename: Filename to use for the configexport method call (default: oxidized.zip)
- ftd\_polls: Number of times to poll the status of the configexport job (default: 10, minimum: 1)
- ftd\_poll\_wait: Seconds to wait between polls (default: 10, minimum: 1)

## Limitations

If your FTDs are in an HA pair, then backups will only succeed on the active device.

Back to [Model-Notes](README.md)
