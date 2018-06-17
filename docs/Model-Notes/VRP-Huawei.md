# Huawei VRP Configuration

Create a user with no privileges

```text
    <HUAWEI> system-view
    [~HUAWEI] aaa
    [~HUAWEI-aaa] local-user oxidized password irreversible-cipher verysecret
    [*HUAWEI-aaa] local-user oxidized level 1
    [*HUAWEI-aaa] local-user oxidized service-type terminal ssh
    [*HUAWEI-aaa] commit
```

The commands Oxidized executes are:

1. screen-length 0 temporary
2. display version
3. display device
4. display current-configuration all

Command 2 and 3 can be executed without issues, but 1 and 4 are only available for higher level users. Instead of making Oxidized a read/write user on your device, lower the privilege-level for commands 1 and 4:

```text
    <HUAWEI> system-view
    [~HUAWEI] command-privilege level 1 view global display current-configuration all
    [*HUAWEI] command-privilege level 1 view shell screen-length
    [*HUAWEI] commit
```

Oxidized can now retrieve your configuration!

Caveat: Some versions of VRP default to appending a timestamp prior to the output of each `display` command, which will lead to superfluous updates. The configuration statement `timestamp disable` can be used to disable this functionality. (Issue #1218)

Back to [Model-Notes](README.md)
