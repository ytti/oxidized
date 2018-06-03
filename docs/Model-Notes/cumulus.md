# Cumulus Linux

## Routing Daemon
With the release of Cumulus Linux 3.4.0 the platform moved the routing daemon 
to a fork of `Quagga` named `FRRouting`. See the below link for the release notes.

[https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes](https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes)

A variable has been added to enable users running Cumulus Linux > 3.4.0 to target the 
new `frr` routing daemon.

### Example usage
```yaml
vars:
  cumulus_routing_daemon: frr
```

```yaml
groups:
  cumulus-new:
    cumulus_routing_daemon: frr
```

```yaml
models: 
  cumulus-new: 
    cumulus_routing_daemon: frr
```

The default variable is `quagga` so existing installations continue to operate without 
interruption.