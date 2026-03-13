# APC Configuration
The configuration of APC Network Management Cards can be downloaded using FTP
and SCP. You can retrieve serial numbers and OS version information through
an SSH connection.

APC OS does not have the ability to display the config.ini within an SSH shell.
A ticket was opened with APC support to enable "cat config.ini"
within an SSH shell, but APC declined to implement this feature.

To overcome this limitation, a capability to run against multiple inputs (SSH + SCP)
has been implemented in Oxidized and in the [model ApcAos](/lib/oxidized/models/apcaos.rb).

The old model apc_aos (SCP/FTP only) is deprecated and will be removed in a
future release. Migrate to ApcAos.

## How do I activate FTP/SCP input?
To download the configuration with FTP or SCP, you must activate it
as an input in the Oxidized configuration. If you don't activate the input,
Oxidized will fail for the node with an error.

You probably also need to increase the default timeout to something about 60
seconds, as the APC are really slow, and need about 30 seconds to complete.

The configuration can be done either globally or only for the ApcAos model.

### Global Configuration
The global configuration would look like this. Note that Oxidized will try every
input type in the given order until it succeeds, or it will report a failure.
```yaml
timeout: 60
input:
  default: ssh, ftp, scp
```
The order in the configuration is relevant. With this configuration, the ApcAos
model will run SSH first, then it will try FTP, and if FTP fails SCP.

### Model-Specific Configuration

Configuration for activating only the SCP input for ApcAos only:
```yaml
input:
  default: ssh
models:
  apcaos:
    input: ssh, scp
    timeout: 60
```

### Setting Specific Credentials
You can also set a specific username and password for ApcAos only:
```yaml
username: default-user
password: default-password
input:
  default: ssh
models:
  ApcAos:
    username: apc-user
    password: apc-password
    input: ssh, scp
    timeout: 60
```

## Why do I partially get CR + LF?
The config.ini file has a DOS-Format (CR + LF), and is saved without
modifications, so that it can be uploaded to the device.

Outputs from ssh are stored without CR, so the first part of the file is
without CR and config.ini with CR + LF.

This is expected behavior and should not affect the functionality of the backup
or restore process.