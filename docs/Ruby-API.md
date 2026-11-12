# Ruby API

The following objects exist in Oxidized.

## Index
- [Input](#input)
  - [http](#http)
- [Output](#output)
- [Source](#source)
- [Model](#model)
  - [At the top level](#at-the-top-level)
    - [cfg](#cfg)
    - [inputs](#inputs)
    - [cmd](#cmd)
    - [comment](#comment)
    - [prompt](#prompt)
    - [expect](#expect)
    - [pre / post](#pre--post)
    - [macro :enable](#macro-enable)
    - [clean :escape_codes](#clean-escape_codes)
    - [clean :cut](#clean-cut)
  - [At the second level](#at-the-second-level)
    - [comment](#comment-1)
    - [password](#password)
    - [post_login](#post_login)
    - [pre_logout](#pre_logout)
    - [send](#send)
    - [cmd](#cmd-1)
  - [Monkey patching](#monkey-patching)
    - [clear: true](#clear-true)
    - [prepend: true](#prepend-true)
  - [Refinements - String Convenience Methods](#refinements)
  - [cut_tail](#cut_tail)
  - [cut_head](#cut_head)
  - [cut_both](#cut_both)
  - [keep_lines](#keep_lines)
  - [reject_lines](#reject_lines)
  - [rstrip_lines](#rstrip_lines)

## Input

* gets config from nodes
* must implement 'connect', 'get', 'cmd'
* 'ssh', 'telnet', 'ftp', 'tftp', 'scp', 'http' implemented

### http

* Communicates with a device over http/https
* Configurable variables from within model @username, @password, @headers.
* @username,@password are used in a Basic Authentication method.
* @headers is a Hash of key value pairs of headers to pass along with the request.
* Within the sources config under input you define a YAML stanza like the below, this will tell Oxidized to validate certificates on the request

```yaml
input:
   http:
     ssl_verify: true
```

## Output

* stores config
* must implement 'store' (may implement 'fetch')
* 'git' and 'file' (store as flat ascii) implemented

## Source

* gets list of nodes to poll
* must implement 'load'
* source can have 'name', 'model', 'group', 'username', 'password', 'input', 'output', 'prompt' for each device.
  * `name` - name of the device
  * `model` - model to use ('ios', 'junos', etc).The model is loaded dynamically by the first node of that model type. (Also default in config file)
  * `input` - method to acquire config, loaded dynamically as needed (Also default in config file)
  * `output` - method to store config, loaded dynamically as needed (Also default in config file)
  * `prompt` - prompt used for node (Also default in config file, can be specified in model too)
* 'sql', 'csv' and 'http' (supports any format with single entry per line, like router.db)

## Model

### At the top level

A model may use several methods at the top level in the class. `cfg` is
executed in input/output/source context. `cmd` is executed within an instance
of the model.

#### `cfg`

`cfg` may be called with a list of methods (`:ssh`, `:telnet`) and a block with
zero parameters.  Calling `cfg` registers the given access methods and calling
it at least once is required for a model to work.

The block may contain commands to change some behaviour for the given methods
(e.g. calling `post_login` to disable the pager).

Example from [ios.rb](/lib/oxidized/model/ios.rb):
```ruby
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end
```

Supports [monkey patching](#monkey-patching).

#### 'inputs'
`inputs` can be used to specify multiple inputs to be run on the model. It
takes a list of either input symbols or lists of input symbols:
```ruby
  inputs [:ssh, %i[scp ftp]]
  inputs [:ssh, :scp]
```

Oxidized will run the model against each item of `inputs`. If an item is a
list of symbols (`%i[scp ftp]`), it will try each input in the order
configured in the `input/default` section of the oxidized configuration file.

If `inputs` is not specified, Oxidized will try each input that has a `cfg`
section in the model, in the order configured in the `input/default` section
of the oxidized configuration file.

To specify which command is to run against which input, use the `input`
parameter of the `cmd` configuration:
```ruby
  cmd 'upsabout', input: :ssh do |cfg|
    comment cfg
  end

  cmd 'config.ini', input: %i[scp ftp] do |cfg|
    "; ========== config.ini ==========\n" + cfg
  end
```

`cmd` without `input` parameter will run against every input.


See the [ApcAos model](/lib/oxidized/model/apcaos.rb) for a full example.


#### `cmd`

Is used to specify commands that should be executed on a model in order to
gather its configuration. It can be called with:

* Just a string
* A string and a block
* `:all` and a block
* `:secret` and a block
* `:significant_changes` and a block

The block takes a single parameter `cfg` containing the output of the command
being processed.

Calling `cmd` with just a string will emit the output of the command given in
that string as configuration.

Calling `cmd` with a string and a block will pass the output of the given
command to the block, then emit its return value (that must be a string) as
configuration.

Calling `cmd` with `:all` and a block will pass all command output through this
block before emitting it. This is useful if some cleanup is required of the
output of all commands.

Calling `cmd` with `:secret` and a block will pass all configuration to the
given block before emitting it to hide secrets if secret hiding is enabled. The
block should replace any secrets with `'<hidden>'` and return the resulting
string.

Calling `cmd` with `:significant_changes` and a block will pass the final
configuration to the given block. The resulting string should contain
significant changes only and will be used to
[decide if the configuration should be stored](Configuration.md#store-configuration-only-on-significant-changes).

Execution order is `:all`, `:secret`, and lastly the command specific block, if
given.

Examples, mostly taken from [ios.rb](/lib/oxidized/model/ios.rb):
```ruby
  # Emit the output as is
  cmd 'show running-config'

  # Emit the output as a comment
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # Remove the command echo and the prompt from every command output
  cmd :all do |cfg|
    cfg.cut_both
  end

  # Hide secrets when remove_secret is enabled
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  # Ignore lines that change without a real configuration change
  cmd :significant_changes do |cfg|
    cfg.reject_lines [
      /^! (Last|No) configuration change (at|since)/,
      '! NVRAM config last updated at'
    ]
  end
```

The `cmd "string"` method accepts a lambda function via the `:if` argument
to execute the command only when the lambda evaluates to true.
The lambda function is evaluated at runtime in the instance context.
See [Conditional `cmd`](Creating-Models.md#conditional-cmd) for details.
```ruby
  cmd 'show vrrp', if: -> { vars(:show_vrrp) } do |cfg|
    comment cfg
  end
```

The `cmd "string"` method accepts a list of supported inputs via the `:input`
argument to limit this command to specific inputs.
```ruby
  cmd 'config.ini', input: %i[scp ftp] do |cfg|
    "; ========== config.ini ==========\n" + cfg
  end
```

Supports [monkey patching](#monkey-patching).

#### pre / post
After all `cmd` have been run, the blocks defined in pre and post are called. The
output of pre will be prepended to the output of the model, The output of post
will be appended.

```ruby
  pre do
    "Prepended output after cmd blocks have been run\n"
  end

  post do
    "Appended output after cmd blocks have been run\n"
  end
```

#### `comment`

Called with a single string containing the string to prepend for comments in
emitted configuration for this model.

If not specified the default of `'# '` will be used (note the trailing space).

```ruby
  comment '! '
```

#### `prompt`

Is called with a regular expression that is used to detect when command output
ends after a command has been executed.

If not specified, a default of `/^([\w.@-]+[#>]\s?)$/` is used.

Example from [procurve.rb](/lib/oxidized/model/procurve.rb), where the prompt
may be preceded by a carriage return:
```ruby
  prompt /^\r?([\w\s.-]+[#>] )$/
```

#### `expect`

Called with a regular expression and a block. The block takes up to two
parameters: the data containing the match, and the regular expression.

The data contains all the output received so far for the current command, and
is replaced by the return value of the block. Use `data.sub re, ''` to remove
only the match; returning an empty string discards all the output received so
far.

`expect` can be used to, for example, strip escape sequences from output before
it's further processed, or to answer interactive questions and pagers.

Example from [fortigate.rb](/lib/oxidized/model/fortigate.rb), handling the
pager:
```ruby
  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end
```

Example from [procurve.rb](/lib/oxidized/model/procurve.rb), answering a
prompt shown after login. As no command has been run yet, the block can discard
the data by returning an empty string:
```ruby
  expect /Press any key to continue$/ do
    send "\n"
    ""
  end
```

Supports [monkey patching](#monkey-patching).

#### `macro :enable`
Implements an [handling of enable](Creating-Models.md#handling-enable-mode) for the model.
```ruby
  macro :enable
  # or, with options:
  macro :enable, inputs: :ssh, command: "su -", regex: /Passwort: /
```

#### `clean :escape_codes`
[Remove ANSI escape codes](Creating-Models.md#remove-ansi-escape-codes) from the output.
```ruby
  clean :escape_codes
```

#### `clean :cut`
Removes (default) the first and last line of the outputs (most of the time
command echo and prompt).
Arguments: head (default: 1), tail (default: 1)
```ruby
  clean :cut, head: 2, tail: 0
```

Equivalent to:
```ruby
  cmd :all do |cfg|
    cfg.cut_both(2, 0)
  end
```


### At the second level

The following methods are available:

#### `comment`

Used inside `cmd` invocations. Comments out every line in the passed string and
returns the result.

```ruby
  cmd 'show version' do |cfg|
    comment cfg
  end
```

#### `password`

Used inside `cfg` invocations to specify the regular expression used to detect
the password prompt. If not specified, the default of `/^Password/` is used.

Similarly, `username` specifies the regular expression for the username prompt
(default: `/^(Username|login)/`).

```ruby
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end
```

#### `post_login`

Used inside `cfg` invocations to specify commands to run once Oxidized has
logged in to the device. Takes one argument that is either a block (taking zero
parameters) or a string containing a command to execute.

This allows `post_login` to be used for any model-specific items prior to
running the regular commands. This could include disabling the output pager
or timestamp outputs that would cause constant differences.

Example from [procurve.rb](/lib/oxidized/model/procurve.rb):
```ruby
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'no page'
  end
```

Supports [monkey patching](#monkey-patching).

#### `pre_logout`

Used to specify commands to run before Oxidized closes the connection to the
device. Takes one argument that is either a block (taking zero parameters) or a
string containing a command to execute.

This allows `pre_logout` to be used to 'undo' any changes that may have been
needed via `post_login` (restore pager output, etc.)

Example from [procurve.rb](/lib/oxidized/model/procurve.rb), answering the
questions asked on logout:
```ruby
  cfg :telnet, :ssh do
    pre_logout 'logout'
    pre_logout 'y'
    pre_logout 'n'
  end
```

Supports [monkey patching](#monkey-patching).

#### `send`

Usually used inside `expect` or blocks passed to `post_login`/`pre_logout`.
Takes a single parameter: a string to be sent to the device. Unlike `cmd`, it
does not wait for the prompt and does not append a newline.

See the examples in [expect](#expect) and [post_login](#post_login).

#### `cmd`
You can nest a `cmd` block inside first level blocks. It will be executed at
runtime.

Example from [nxos.rb](/lib/oxidized/model/nxos.rb):
```ruby
  cmd 'show inventory all' do |cfg|
    if cfg.match? /^% Invalid .* at '\^' marker\./
      # 'show inventory all' isn't supported on older versions
      cfg = cmd 'show inventory'
    end
    comment cfg
  end
```

See [Conditional commands](Creating-Models.md#conditional-commands) for more
examples.

### Monkey patching

Several model blocks accept behavior-modifying arguments that make monkey
patching existing blocks easier. This is primarily useful when a user-supplied
model aims to override or extend existing behavior of a model included in Oxidized.

This functionality is supported by `cfg`, `cmd`, `pre_*`, `post_*`, and `expect`
blocks.

#### `clear: true`
Resets the existing block, allowing the user to completely override its contents.

```ruby
  cmd 'show version', clear: true do |cfg|
    comment cfg
  end
```

#### `prepend: true`

Ensures that the contents of the block are prepended, rather than appended (the
default) to an existing block.

```ruby
  cfg :ssh, prepend: true do
    post_login 'terminal no-more'
  end
```

### Refinements

#### `String` convenience methods

Since configuration processing tasks are occasionally similar across models,
Oxidized provides an refined [`String`](../lib/refinements.rb) class with the
intention of providing convenience methods and eliminating code duplication.

A model must activate the refinements with `using Refinements`:
```ruby
class IOS < Oxidized::Model
  using Refinements
  # ...
end
```

#### `cut_tail`

Returns a multi-line string without the last line, or an empty string if only a
single line was present. Takes an optional number of lines to remove (default: 1).

Example from [axos.rb](/lib/oxidized/model/axos.rb), removing the prompt:
```ruby
  cmd :all do |cfg|
    cfg.cut_tail
  end
```

#### `cut_head`

Returns a multi-line string without the first line, or an empty string if only a
single line was present. Takes an optional number of lines to remove (default: 1).

```ruby
  # Remove the command echo and the "Building configuration..." lines
  cfg = cfg.cut_head(3)
```

#### `cut_both`

Returns a multi-line string without the first and last lines, or an empty string
if fewer than three lines were present. Takes optional numbers of lines to remove
at the head and the tail (default: 1 and 1).

This is typically used to remove the command echo (first line) and the prompt
(last line), which are not needed in the stored configuration:
```ruby
  cmd :all do |cfg|
    cfg.cut_both
  end
```

#### `keep_lines`
Returns a multi-line string with only the lines matching any pattern (String or Regexp) given in an array.

```ruby
  cmd 'show interfaces transceiver' do |cfg|
    cfg = cfg.keep_lines [
      'SFP Information',
      /Vendor (Name|Serial Number)/
    ]
    comment cfg
  end
```

#### `reject_lines`
Returns a multi-line string without the lines matching any pattern (String or Regexp) given in an array.

Example from [arubainstant.rb](/lib/oxidized/model/arubainstant.rb), removing
lines that change on every run:
```ruby
  cmd 'show version' do |cfg|
    cfg = cfg.reject_lines [
      /^(Switch|AP) uptime is /,
      /^Reboot Time and Cause/
    ]
    comment cfg
  end
```

#### `rstrip_lines`
Returns a multi-line string with trailing whitespace (including `\r`) removed
from each line. The result always ends with a single newline.

Example from [procurve.rb](/lib/oxidized/model/procurve.rb), removing the
trailing spaces that `comment` adds to empty lines (`"! "`):
```ruby
  def clean_comment(lines)
    comment(lines).rstrip_lines
  end
```
