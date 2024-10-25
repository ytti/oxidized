# Device simulation
Oxidized supports [150+ devices](/docs/Supported-OS-Types.md).
No developer has access to all of these devices, which makes the task of
maintaining Oxidized difficult:

- issues can't be resolved because the developer has no access to the device.
- further developments can produce regressions.

In order to address this, we can simulate the devices. An example for a
simulation are the [model unit tests](/spec/model) but one could also simulate
a device within a ssh server.

The simulation of devices is currently focused on ssh-based devices. This may
be extended to other inputs like telnet or ftp in the future.

## YAML Simulation Data
The underlying data for the simulation is a [YAML](https://yaml.org/) file in
which we store all relevant information about the device. The most important
information is the responses to the commands used in the oxidized models.

The YAML simulation files are stored under
[/examples/device-simulation/yaml/](/examples/device-simulation/yaml/).

### Creating a YAML file with device2yaml.rb
A device does not only output the ASCII text we can see in the console.
It adds ANSI-escape code for nice colors, bold and underline, \r and so on.
These are key factors in prompt issues so they must be represented in the YAML
file. We use the ruby string format with interpolations like \r \e and so on.
Another important point is trailing spaces at the end of lines. Some text
editors automatically remove trailing spaces, so we code them with \x20.

Although a YAML file could be written by hand, this is quite a tedious task to
catch all the extra codes and code them into YAML. This can be
automated with the ruby script
[device2yaml.rb](/examples/device-simulation/device2yaml.rb).

`device2yaml.rb` needs ruby and the gem
[net-ssh](https://rubygems.org/gems/net-ssh/) to run. On debian, you can install
them with `sudo apt install ruby-net-ssh`

Run `device2yaml.rb` in the directory `/examples/device-simulation/`, the
online help tells you the options.
```
device-simulation$ ./device2yaml.rb
Missing a host to connect to...

Usage: device2yaml.rb [user@]host [options]
    -c, --cmdset file                Mandatory: specify the commands to be run
    -o, --output file                Specify an output YAML-file
    -t, --timeout value              Specify the idle timeout beween commands (default: 5 seconds)
    -e, --exec-mode                  Run ssh in exec mode (without tty)
    -h, --help                       Print this help
```

- `[user@]host` specifies the user and host to connect to the device. The
password will be prompted interactively by the script. If you do not specify a
user, it will use the user executing the script.
- You must list the commands you want to run on the device in a file. Just
enter one command per line. It is important that you enter exactly the commands
used by the oxidized model, and no abbreviation like `sh run`. Do not forget
to insert the `post_login` commands at the beginning if the model has some and
also the `pre_logout`commands at the end.
Predefined command sets for some models are stored in
`/examples/device-simulation/cmdsets`.
- `device2yaml.rb` waits an idle timeout after the last received data before
sending the next command. The default is 5 seconds. If your device makes a
longer pause than 5 seconds before or within a command, you will see that the
output of the command is shortened or slips into the next command in the yaml
file. You will have to change the idle timeout to a greater value to address
this.
- When run without the output argument, `device2yaml.rb` will only print the ssh
output to the standard output. You must use `-o <model_HW_SW.yaml>` to store the
collected data in a YAML file.
- If your oxidized model uses ssh exec mode (look for `exec true` in the model),
you will have to use the option `-e` to run device2yaml in ssh exec mode.

Note that `device2yaml.rb` takes some time to run because of the idle
timeout of (default) 5 seconds between each command. You can press the "Escape"
key if you know there is no more data to come for the current command (when you
see the prompt for the next command), and the script will stop waiting and
directly process the next command.

Here are two examples of how to run the script:
```shell
./device2yaml.rb OX-SW123.sample.domain -c cmdsets/aoscx -o yaml/aoscx_R8N85A-C6000-48G-CL4_PL.10.08.1010.yaml
./device2yaml.rb admin@r7 -c cmdsets/routeros -e -o yaml/routeros_CHR_7.10.1.yaml
```

### Publishing the YAML simulation file to oxidized
Publishing the YAML simulation file of your device helps maintain oxidized.
This task may take some time, and we are very grateful that you take this time
for the community!

You should pay attention to removing or replacing anything you don't want to
share with the rest of the world, for example:

- Passwords
- IP Adresses
- Serial numbers

You can also shorten the configuration if you want - we don't need 48 times the
same config for each interface, but it doesn't hurt either.

Take your time, this is an important task: after you have
uploaded your file on github, it may be impossible to remove it. You can use
search/replace to make consistent and faster changes (change the hostname).

You can leave the section `oxidized_output` unchanged, it is only used for
[model unit tests](/spec/model). You will find an explanation of how to produce
the `oxidized_output`-section in the README.md there.

The YAML simulation file should be stored under
[/examples/device-simulation/yaml/](/examples/device-simulation/yaml/. It
should be named so that it can be easily recognized: model, hardware type,
software version and optionally a description if you need to differentiate two
YAML files:

- #model_#hardware_#software.yaml
- #model_#hardware_#software_#description.yaml

Examples:

- garderos_R7709_003_006_068.yaml
- iosxe_C9200L-24P-4G_17.09.04a.yaml
- asa_5512_9.12-4-67_single-context.yaml

### Interactive mode
The `device2yaml.rb` script is a little dumb and needs some help, especially
when having a device sending its output page by page and requiring you to press
space for the next page. `device2yaml.rb` does not know how to handle this.

While `device2yaml.rb` is running, you can type anything to the keyboard, it
will be send to the remote device. So you can press space or 'n' to get the
next page.

You can also use this to enter an enable password.

If you press the "Esc" key, `device2yaml.rb` will not wait for the idle timeout
and will process the next command right away.

### YAML Format
The yaml file has three sections:
- init_prompt: describing the lines send by the device before we can send a
command. It usually includes MOTD banners, and must include the first prompt.
- commands: the commands the oxidized model sends to the network device and the
expected output.
- oxidized_output: the expected output of oxidized, so that you can compare it
to the output generated by the unit test. This is optional and only used for
unit tests.

The outputs are multiline and use YAML block scalars (`|`), with the trailing \n
removed (`-` after `|`). The outputs include the echo of the given command and
the next prompt. Escape characters are coded in Ruby style (\n, \r...).

Here is a shortened example of a YAML file:
```yaml
---
init_prompt: |-
  \e[4m\rLAB-R1234_Garderos#\e[m\x20
commands:
  show system version: |-
    show system version
    grs-gwuz-armel/003_005_068 (Garderos; 2021-04-30 16:19:35)
    \e[4m\rLAB-R1234_Garderos#\e[m\x20
# ...
  exit: ""
oxidized_output: |
  # grs-gwuz-armel/003_005_068 (Garderos; 2021-04-30 16:19:35)
  #\x20
# ...
```


