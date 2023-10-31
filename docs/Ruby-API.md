# Ruby API

The following objects exist in Oxidized.

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

Supports [monkey patching](#monkey-patching).

#### `cmd`

Is used to specify commands that should be executed on a model in order to
gather its configuration. It can be called with:

* Just a string
* A string and a block
* `:all` and a block
* `:secret` and a block

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

Execution order is `:all`, `:secret`, and lastly the command specific block, if
given.

Supports [monkey patching](#monkey-patching).

#### `comment`

Called with a single string containing the string to prepend for comments in
emitted configuration for this model.

If not specified the default of `'# '` will be used (note the trailing space).

#### `prompt`

Is called with a regular expression that is used to detect when command output
ends after a command has been executed.

If not specified, a default of `/^([\w.@-]+[#>]\s?)$/` is used.

#### `expect`

Called with a regular expression and a block. The block takes two parameters:
the regular expression, and the data containing the match.

The passed data is replaced by the return value of the block.

`expect` can be used to, for example, strip escape sequences from output before
it's further processed.

Supports [monkey patching](#monkey-patching).

### At the second level

The following methods are available:

#### `comment`

Used inside `cmd` invocations. Comments out every line in the passed string and
returns the result.

#### `password`

Used inside `cfg` invocations to specify the regular expression used to detect
the password prompt. If not specified, the default of `/^Password/` is used.

#### `post_login`

Used inside `cfg` invocations to specify commands to run once Oxidized has
logged in to the device. Takes one argument that is either a block (taking zero
parameters) or a string containing a command to execute.

This allows `post_login` to be used for any model-specific items prior to
running the regular commands. This could include disabling the output pager
or timestamp outputs that would cause constant differences.

Supports [monkey patching](#monkey-patching).

#### `pre_logout`

Used to specify commands to run before Oxidized closes the connection to the
device. Takes one argument that is either a block (taking zero parameters) or a
string containing a command to execute.

This allows `pre_logout` to be used to 'undo' any changes that may have been
needed via `post_login` (restore pager output, etc.)

Supports [monkey patching](#monkey-patching).

#### `send`

Usually used inside `expect` or blocks passed to `post_login`/`pre_logout`.
Takes a single parameter: a string to be sent to the device.

### Monkey patching

Several model blocks accept behavior-modifying arguments that make monkey
patching existing blocks easier. This is primarily useful when a user-supplied
model aims to override or extend existing behavior of a model included in Oxidized.

This functionality is supported by `cfg`, `cmd`, `pre_*`, `post_*`, and `expect`
blocks.

#### `clear: true`

Resets the existing block, allowing the user to completely override its contents.

#### `prepend: true`

Ensures that the contents of the block are prepended, rather than appended (the
default) to an existing block.

### Refinements

#### `String` convenience methods

Since configuration processing tasks are occasionally similar across models,
Oxidized provides an refined [`String`](../lib/refinements.rb) class with the
intention of providing convenience methods and eliminating code duplication.

#### `cut_tail`

Returns a multi-line string without the last line, or an empty string if only a
single line was present.

#### `cut_head`

Returns a multi-line string without the first line, or an empty string if only a
single line was present.

#### `cut_both`

Returns a multi-line string without the first and last lines, or an empty string
if fewer than three lines were present.
