# Cumulus Linux

## Routing Daemon

With the release of Cumulus Linux 3.4.0 the platform moved the routing daemon to a fork of `Quagga` named `FRRouting`. See the below link for the release notes.

[https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes](https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes)

A variable has been added to enable users running Cumulus Linux > 3.4.0 to target the new `frr` routing daemon.

### Example usage

```yaml
vars:
  cumulus_routing_daemon: frr
```

Alternatively map a column for the  `cumulus_routing_daemon` variable.

```yaml
source:
  csv:
    map:
      name: 0
      ip: 1
      model: 2
      group: 3
    vars_map:
      cumulus_routing_daemon: 4
```

And set the `cumulus_routing_daemon` variable in the `router.db` file.

```text
cumulus1:192.168.121.134:cumulus:cumulus:frr
```

The default variable is `quagga` so existing installations continue to operate without interruption.

Back to [Model-Notes](README.md)
