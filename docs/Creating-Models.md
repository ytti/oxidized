# Creating and Extending Models

Oxidized supports a growing list of [operating system types](Supported-OS-Types.md). Out of the box, most model implementations collect configuration data. Some implementations also include a conservative set of additional commands that collect basic device information (device make and model, software version, licensing information, ...) which are appended to the configuration as comments.

A user may wish to extend an existing model to collect the output of additional commands. Oxidized offers smart loading of models in order to facilitate this with ease, without the need to introduce changes to the upstream source code.

This methodology allows local site changes to be preserved during Oxidized version updates / gem updates. It also enables convenient local development of new models.

## Index
- [Creating a new model](#creating-a-new-model)
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

## Create unit tests for the model
> :warning: model unit tests are still a work in progress and need some polishing.

If you want the model to be integrated into oxidized, you can
[submit a pull request on github](https://github.com/ytti/oxidized/pulls).
This is a greatly appreciated submission, as there are probably other users
using the same network device as you are.

A good (and optional) practice for submissions is to provide a
[unit test for your model](/spec/model). This reduces the risk that further
developments don't break it, and facilitates debugging issues without having
access to a physical network device for the model.

In order to simulate the device in the unit test, you need a
[YAML simulation file](/examples/device-simulation/), have a look at the
link for an explanation on how to create one.

Creating the unit test itself is explained in
[README.md in the model unit test directory](/spec/model/README.md).

Remember - producing a YAML simulation file and/or writing a unit test is
optional.
The most value comes from the YAML simulation file. The unit
test can be written by someone else, but you need access to the device for the
YAML simulation file. If you encounter problems, open an issue or ask for help
in your pull request.

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
