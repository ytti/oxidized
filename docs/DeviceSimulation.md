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
[/spec/model/data/](/spec/model/data/), with the naming convention
`model:description:simulation.yaml`, in which `model` is the lowercase name
of the oxidized model and `description` is the name of the test case and is
generally formatted as #hardware_#software or
#model_#hardware_#software_#description.

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
[extras/device2yaml.rb](/extras/device2yaml.rb).

`device2yaml.rb` needs ruby and the gem
[net-ssh](https://rubygems.org/gems/net-ssh/) to run. On debian, you can install
them with `sudo apt install ruby-net-ssh`

Run `extras/device2yaml.rb`, the online help tells you the options.
```
oxidized$ extra/device2yaml.rb
Missing a host to connect to...

Usages:
- device2yaml.rb [user@]host -i file [options]
- device2yaml.rb [user@]host -c "command1
  command2
  command3" [options]

-i and -c are mutualy exclusive, one must be specified

[options]:
    -c, --commands "command list"    specify the commands to be run
    -i, --input file                 Specify an input file for commands to be run
    -o, --output file                Specify an output YAML-file
    -t, --timeout value              Specify the idle timeout beween commands (default: 5 seconds)
    -e, --exec-mode                  Run ssh in exec mode (without tty)
    -h, --help                       Print this help
```

- `[user@]host` specifies the user and host to connect to the device. The
password will be prompted interactively by the script. If you do not specify a
user, it will use the user executing the script.
- The commands that will be run on the device must be defined
in `deviceyaml.rb`. You can give the commands online with `-c` or read them
from a file (one line per command) with `-i`. The commands should match exactly
the one of the model (no abbreviations) and include the command of the
`post_login` and `pre_logout` sections. When using -c and editing the command
line, `CTRL-V CTRL-J` is very useful to add a new line.
- `device2yaml.rb` waits an idle timeout after the last received data before
sending the next command. The default is 5 seconds. If your device makes a
longer pause than 5 seconds before or within a command, you will see that the
output of the command is shortened or slips into the next command in the YAML
file. You will have to change the idle timeout to a greater value to address
this.
- When run without the output argument, `device2yaml.rb` will only print the ssh
output to the standard output. You must use `-o <model:HW_SW:simulation.yaml>`
to store the collected data in a YAML file.
- If your oxidized model uses ssh exec mode (look for `exec true` in the model),
you will have to use the option `-e` to run device2yaml in ssh exec mode.

Note that `device2yaml.rb` takes some time to run because of the idle
timeout of (default) 5 seconds between each command. You can press the "Escape"
key if you know there is no more data to come for the current command (when you
see the prompt for the next command), and the script will stop waiting and
directly process the next command.

Running the script against an ios device would look like:
```shell
extra/device2yaml.rb oxidized@r61 -c "terminal length 0
terminal width 0
show version
show vtp status
show inventory
show running-config
exit" -o spec/model/data/ios:C8200L_16.12.1:simulation.yaml
```

### Publishing the YAML simulation file to oxidized
Publishing the YAML simulation file of your device helps maintain oxidized.
This task may take some time, and we are very grateful that you take this time
for the community!

You should pay attention to removing or replacing anything you don't want to
share with the rest of the world, for example:

- Passwords
- IP Addresses
- Serial numbers

You can also shorten the configuration if you want - we don't need 48 times the
same configuration for each interface, but it doesn't hurt either.

Take your time, this is an important task: after you have
uploaded your file on github, it may be impossible to remove it. You can use
search/replace to make consistent and faster changes (change the hostname).

The YAML simulation files are stored under
[/spec/model/data/](/spec/model/data/), with the naming convention
`model:description:simulation.yaml`, in which `model` is the lowercase name
of the oxidized model and `description` is the name of the test case and is
generally formatted as #hardware_#software or
#model_#hardware_#software_#description.

Using a correct name for the file is important in order to be included in
automatic model unit tests.

Examples:

- spec/model/data/aoscx:R0X25A-6410_FL.10.10.1100:simulation.yaml
- spec/model/data/asa:5512_9.12-4-67_single-context:simulation.yaml
- spec/model/data/ios:C9200L-24P-4G_17.09.04a:simulation.yaml


When you are finished, commit and push to your forked repository on github, and
submit a Pull Request. Thank you for your help!

### Interactive mode
The `device2yaml.rb` script is dumb and sometimes needs some help, especially
when having a device sending its output page by page and requiring you to press
space for the next page. `device2yaml.rb` does not know how to handle this.

While `device2yaml.rb` is running, you can type anything to the keyboard, it
will be send to the remote device. So you can press space or 'n' to get the
next page.

You can also use this to enter an enable password.

If you press the "Esc" key, `device2yaml.rb` will not wait for the idle timeout
and will process the next command right away.

### YAML Format
The yaml file has two sections:
- init_prompt: describing the lines send by the device before we can send a
command. It usually includes MOTD banners, and must include the first prompt.
- commands: the commands the oxidized model sends to the network device and the

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
```


