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
If you want the model to be integrated into oxidized, you can
[submit a pull request on github](https://github.com/ytti/oxidized/pulls).
This is a greatly appreciated submission, as there are probably other users
using the same network device as you are.

We ask you to write a unit test for the model, in order to be sure further developments don't break your model,
and to facilitate debugging issues without having access to a physical network device for the model. Writing a
model unit test for SSH should be straightforward, and it is described in the next lines. Most of the work is
writing a yaml file with the commands and their output, the ruby code itself is copy & paste with a few
modifications. If you encounter problems, open an issue or ask for help within the pull request.

You can have a look at the [Garderos unit test](/spec/model/garderos_spec.rb) for an example. The model unit test
consists of (at least) two files:
- a yaml file under `examples/model/`, containing the data used to simulate the network device.
  - Please name your file `<model>_<hardware type>_<software_version>.yaml`, for example in the garderos unit test: `garderos_R7709_003_006_068.yaml`.
  - You can create multiple files in order to support multiple devices or software versions.
  - You may append a comment after the software version to differentiate between two tested features (something like `garderos_R7709_003_006_068_with_ipsec.yaml`).
- a ruby script containing the tests under `spec/model/`.
  - It is named `<model>_spec.rb`, for the garderos model: `garderos_spec.rb`.
  - The script described below is a minimal example; you can add as many tests as needed.

### YAML description to simulate the network device.
The yaml file has three sections:
- init_prompt: describing the lines send by the device before we can send a command. It may include motd banners, and mus include the first prompt.
- commands: the commands the model sends to the network device and the expected output. Do not forget the command needed to logout from the device.
- oxidized_output: the expected output of oxidized, so that you can compare it to the output generated by the unit test.

The outputs are multiline and use yaml block scalars (`|`), with the trailing \n removed (`-` after `|`). The outputs includes the echo of the given command and the next prompt. Some escape characters are interpreted, currently \n, \r, \x\<octal char number\>, \\\\

Here is a shortened example of a YAML file:
```yaml
---
# Trailing white spaces are coded as \x20 because some editors automatically remove trailing white spaces
init_prompt: |-
  \e[4m\rLAB-R1234_Garderos#\e[m\x20
commands:
  show system version: |-
    show system version
    grs-gwuz-armel/003_005_068 (Garderos; 2021-04-30 16:19:35)
    \e[4m\rLAB-R1234_Garderos#\e[m\x20
# ...
  exit: ""
oxidized_output: |-
  # grs-gwuz-armel/003_005_068 (Garderos; 2021-04-30 16:19:35)
  #\x20
# ...
```

### Model unit test
When creating the unit test, it is handy to have a specific section for testing different
prompts without testing the whole configuration. This is done by the first test in the following
example. The second tests takes the defined yaml file, runs the model against it and
compares the result against the yaml-section `oxidized_output`.

```ruby
require_relative 'model_helper'

describe 'model/Garderos' do
  # For each test, we initialize oxidized to some default values
  # and create a node with the model we want to test
  # replace 'garderos' with your model
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'garderos')
  end

  it 'matches different prompts' do
    _('LAB-R1234_Garderos# ').must_match Garderos.prompt
  end

  # Name the test after the tesed HW and SW. Link to your yaml data
  it 'runs on R7709 with OS 003_006_068' do
    mockmodel = MockSsh.new('examples/model/garderos_R7709_003_006_068.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
```

The unit tests use [minitest/spec](https://github.com/minitest/minitest?tab=readme-ov-file#specs-) and [mocha](https://github.com/freerange/mocha).
If you need more expectations for you tests, have a look at the [minitest documentation for expectations](https://docs.seattlerb.org/minitest/Minitest/Expectations.html)

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
