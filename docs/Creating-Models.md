# Creating and Extending Models

Oxidized supports a growing list of [operating system types](Supported-OS-Types.md). Out of the box, most model implementations collect configuration data. Some implementations also include a conservative set of additional commands that collect basic device information (device make and model, software version, licensing information, ...) which are appended to the configuration as comments.

A user may wish to extend an existing model to collect the output of additional commands. Oxidized offers smart loading of models in order to facilitate this with ease, without the need to introduce changes to the upstream source code.

This methodology allows local site changes to be preserved during Oxidized version updates / gem updates. It also enables convenient local development of new models.

## Index
- [Creating a new model](#creating-a-new-model)
- [Typical Tasks and Solutions](#typical-tasks-and-solutions)
  - [Handling 'enable' mode](#handling-enable-mode)
  - [Remove ANSI escape codes](#remove-ansi-escape-codes)
  - [Conditional commands](#conditional-commands)
- [Extending an existing model with a new command](#extending-an-existing-model-with-a-new-command)
- [Create unit tests for the model](#create-unit-tests-for-the-model)
- [Advanced features](#advanced-features)
- [Monkey-patching blocks in existing models](#monkey-patching-blocks-in-existing-models)
- [Help](#help)

## Creating a new model

An Oxidized model, at minimum, requires just three elements:

* A model file, this file should be placed in the ~/.config/oxidized/model directory and named after the target OS type.
* A class defined within this file with the same name as the file itself that inherits from `Oxidized::Model`, the base model class.
* At least one command that will be executed and the output of which will be collected by Oxidized.

A bare-bone example for a fictional model running the OS type `rootware` could be introduced by creating the file `~/.config/oxidized/model/rootware.rb`, with the following content:

```ruby
class RootWare < Oxidized::Model
  using Refinements
  
  cmd 'show complete-config'

  cfg :ssh do
    pre_logout 'exit'
  end
end
```

This model, as-is will:

* Log into the device with ssh and expect the default prompt.
* Upon matching it, execute the command `show complete-config`
* Collect the output.
* Logout with the command `exit`

It is often useful to, at minimum, define the following additional elements for any newly introduced module:

* A regexp for the prompt, via the `prompt` statement.
* A comment prefix, via the `comment` statement.
* A regexp for telnet username and password prompts.
* A mechanism for handling `enable` or similar functionality.

The API documentation contains a list of [methods](https://github.com/ytti/oxidized/blob/master/docs/Ruby-API.md#model) that can be used in modules.

A more fleshed out example can be found in the `IOS` and `JunOS` models.

## Typical Tasks and Solutions

### Keep or Remove Lines Returned from a Command
To make command output cleaner, you can remove unwanted lines or keep only
specific ones.

Most devices echo the executed command on the first line and display a
prompt on the last line. To remove these for all commands, use
[cut_both](Ruby-API.md#cut_both):
```ruby
  cmd :all do |cfg|
    cfg.cut_both
  end
```

If you want to keep only relevant lines, use
[keep_lines](Ruby-API.md#keep_lines):
```ruby
  cmd 'show interfaces transceiver' do |cfg|
    cfg = cfg.keep_lines [
      'SFP Information',
      /Vendor (Name|Serial Number)/
    ]
    comment cfg + "\n"
  end
```

If you want to suppress specific lines,
use [reject_lines](Ruby-API.md#reject_lines):
```ruby
  cmd 'show running-config' do |cfg|
    cfg.reject_lines [
      'System Up Time',
      /Current .* Time:/
    ]
  end
```

### Handling 'enable' mode
The following code snippet demonstrates how to handle sending the 'enable'
command and an enable password.

This example is taken from the `IOS` model. It covers scenarios where users
need to enable privileged mode, either without providing a password (by setting
`enable: true` in the configuration) or with a password.

```ruby
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
  end
```
Note: Remove `:telnet, ` if your device does not support telnet.

### Remove ANSI Escape Codes
Some devices produce [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands)
to enhance the appearance of their output.
However, this can make prompt matching difficult and some of these ANSI escape
codes might end up in the resulting configuration.

You can remove most ANSI escape codes by inserting the following line in your
model:
```ruby
  clean :escape_codes
```

When using clean `:escape_codes`, you don't have to worry about escape codes 
in your prompt regexp, as they will be removed before the prompt detection runs.

If it doesn't work for your model, please open an issue and provide a
[device simulation file](/docs/DeviceSimulation.md) so that we can adapt the
code.

### Conditional commands
Some times, you have to run commands depending on the output of the device or
a configured variable. For this, there are at least three solutions.

#### Nested `cmd`
You can nest `cmd` inside [`cmd` blocks](Ruby-API.md#cmd), the following example
is taken from [nxos.rb](/lib/oxidized/model/nxos.rb):
```ruby
  cmd 'show inventory all' do |cfg|
    if cfg.include? "% Invalid parameter detected at '^' marker."
      # 'show inventory all' isn't supported on older versions (See Issue #3657)
      cfg = cmd 'show inventory'
    end
    comment cfg
  end
```

#### pre/post blocks
After all the [`cmd` blocks](Ruby-API.md#cmd) have been run, the [`pre`
and `post` blocks](Ruby-API.md#pre--post) are run. The following example is
taken from [junos.rb](/lib/oxidized/model/junos.rb):
```ruby
  post do
    out = String.new
    case @model
    when 'mx960'
      out << cmd('show chassis fabric reachability') { |cfg| comment cfg }
    when /^(ex22|ex3[34]|ex4|ex8|qfx)/
      out << cmd('show virtual-chassis') { |cfg| comment cfg }
    when /^srx/
      out << cmd('show chassis cluster status') do |cfg|
        cfg.lines.count <= 1 && cfg.include?("error:") ? String.new : comment(cfg)
      end
    end
    out
  end
```

In [pre/post blocks](Ruby-API.md#pre--post), you can also use dynamic generated
commands, for example in [eatonnetwok.rb](/lib/oxidized/model/eatonnetwork.rb):
```ruby
  post do
    cmd "save_configuration -p #{@node.auth[:password]}"
  end
```

#### Conditional `cmd`
The `cmd "string"` method for accepts a lambda function via the `:if` argument
to execute the command only when the lambda evaluates to true.
The lambda function is evaluated at runtime in the instance context.

```ruby
  cmd 'conditional command', if: lambda {
    # Use lambda when multiple lines are needed
    vars("condition")
  } do |cfg|
    @run_second_command = "go"
    comment cfg
  end

  cmd 'second command', if: -> { @run_second_command == "go" } do |cfg|
    comment cfg
  end
```

## Extending an existing model with a new command

The example below can be used to extend the `JunOS` model to collect the output of `show interfaces diagnostics optics` and append the output to the configuration file as a comment. This command retrieves DOM information on pluggable optics present in a `JunOS`-powered chassis.

Create the file `~/.config/oxidized/model/junos.rb` with the following contents:

```ruby
require 'oxidized/model/junos.rb'


class JunOS
  using Refinements

  cmd 'show interfaces diagnostics optics' do |cfg|
    comment cfg
  end


end
```

Due to smart loading, the user-supplied `~/.config/oxidized/model/junos.rb` file will take precedence over the model with the same name included in the Oxidized distribution.

The code then uses `require` to initially load the Oxidized-supplied model, and extends the class defined therein with an additional command.

Intuitively, it is also possible to:

* Completely re-define an existing model by creating a file in `~/.config/oxidized/model/` with the same name as an existing model, but not `require`-ing the upstream model file.
* Create a named variation of an existing model, by creating a file with a new name (such as `~/.config/oxidized/model/junos-extra.rb`), Then `require` the original model and extend its base class as in the above example. The named variation can then be specified as an OS type for specific devices that can benefit from the extra functionality. This allows for preservation of the base functionality for the default model types.
* Create a completely new model, with a new name, for a new operating system type.
* Testing/validation of an updated model from the [Oxidized GitHub repo models](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model) by placing an updated model in the proper location without disrupting the gem-supplied model files.

## Create Unit Tests for the Model
If you want the model to be integrated into Oxidized, you can
[submit a pull request on GitHub](https://github.com/ytti/oxidized/pulls).
This is a greatly appreciated submission, as there are probably other users
using the same network device as you are.

A good (and optional) practice for submissions is to provide a
[unit test for your model](/docs/ModelUnitTests.md). This reduces the risk that
further developments could break it, and facilitates debugging issues without
having access to a physical network device for the model.

## Advanced features

The loosely-coupled architecture of Oxidized allows for easy extensibility in more advanced use cases as well.

The example below extends the functionality of the `JunOS` model further to collect `display set` formatted configuration from the device, and utilizes the multi-output functionality of the `git` output to place the returned configuration in a separate file within a git repository.

It is possible to configure the `git` output to create new subdirectories under an existing repository instead of creating new repositories for each new defined output type (the default) by including the following configuration in the `~/.config/oxidized/config` file:

```yaml
output:
    git:
        type_as_directory: true
```

Then, `~/.config/oxidized/model/junos.rb` is adapted as following:

```ruby
require 'oxidized/model/junos.rb'


class JunOS
  using Refinements

  cmd 'show interface diagnostic optics' do |cfg|
    comment cfg
  end

  cmd 'show configuration | display set' do |cfg|
    cfg.type = "junos-set"
    cfg.name = "set"
    cfg
  end
end
```

The output of the `show configuration | display set` command is marked with a new arbitrary alternative output type, `junos-set`.  The `git` output will use the output type to create a new subdirectory by the same name. In this subdirectory, the `git` output will create files with the name `<devicename>--set` that will contain the output of this command for each device.

## Monkey-patching blocks in existing models

In addition to adding new commands and blocks to existing models, Oxidized offers convenience methods for monkey-patching existing commands and blocks within existing models.

When defining a monkey-patched block, two boolean arguments can be passed as part of the block definition:

* `clear: true`, which resets the existing block, allowing the user to completely override its contents.
* `prepend: true`, which ensures that the contents of the block are prepended, rather than appended (the default) to an existing block.

This functionality is supported for `cfg`, `cmd`, `pre`, `post`, and `expect` blocks.

Examples:

```ruby
cmd :secret, clear: true do
  # ... "(new code for secret removal which replaces the existing :secret definition in the model)" ...
end
```

```ruby
cmd 'show version', clear: true do |cfg|
  # ... "(new code for parsing 'show version', replaces the existing definition in the model)" ...
end
```

```ruby
cmd :ssh, prepend: true do
  # ... "(code that should run first, before any code in the existing :ssh definition in the model)" ...
end
```

## Help

If you experience difficulties creating a new model, you can often get help by installing an Internet reachable sanitized device and opening a new issue on Github asking for help with creating the model. You should research what is the device vendor name is, the vendor's OS type name is, the exact device model name and firmware version. This information should be included in the issue.
