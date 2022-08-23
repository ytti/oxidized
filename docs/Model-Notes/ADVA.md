# ADVA Configuration

To ensure Oxidized can fetch the configuration, you have to make sure that `cli-paging` is set to `disabled` for the user that is used to connect to the ADVA devices.

## Restoring the configuration

In order to trick the device into restoring the files you need to add the following remarks as first line of the file.
```
# DO NOT EDIT THIS LINE. FILE_TYPE=CONFIGURATION_FILE
```

Back to [Model-Notes](README.md)
