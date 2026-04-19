# Cisco Nexus 3550-F (ExaLink Fusion)

The Cisco Nexus 3550-F (formerly Exablaze ExaLink Fusion) is an ultra-low-latency
Layer 1/2 switch platform based on FPGA technology, primarily used in high-frequency
trading and HPC environments. It runs a custom Linux-based OS with a proprietary CLI
and JSON RPC API.

## Device Configuration

Create a read-only user for Oxidized on the device:

```
admin@N3550-F> configure user oxidized password <password>
admin@N3550-F> configure user oxidized privilege read-only
```

## Oxidized Configuration

```yaml
source:
  default: csv
  csv:
    file: "/home/oxidized/.config/oxidized/router.db"
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
```

Example `router.db` entry:

```bash
myswitch.example.com:exalink
```

## Notes

- Both SSH and Telnet are supported. SSH is recommended.
- The model collects `show version` (excluding uptime to avoid noisy diffs),
  `show port`, and `show running-config`.
- Timestamps (`!Time:`) are stripped from the running config to avoid noisy diffs.
- The device prompt format is `hostname#` or `hostname>`.
- This model was developed and tested against software version 1.16.0.
