# Frequently Asked Questions

## Troubleshooting

Q) I've tried Oxidized with a supported device but no (or partial) configuration is collected, authentication and everything else seems fine - how come?

A common reason for configuration collection to fail after successful authentication is prompt mismatches. The symptoms typically fall into one of two categories:

- Oxidized successfully logs into the device, then reports a timeout without collecting configuration. This can be caused by an unmatched prompt.
- Only partial output is collected and collection stops abruptly. This can be caused by overly greedy prompt being matched against non-prompt output.

*Troubleshooting an unmatched prompt:*

Log in manually into the device. Use the same username and password or key configured for Oxidized. Observe the prompt returned by the device.

```text
Logging into this device is dangerous! Do so at your own risk.

Username: superuser
Password: *********

Welcome to the advanced nuclear launchinator 5A-X20. Proceed with caution.

SEKRET-5A-X20#
```

Review the relevant device model file and identify the defined prompt. You can find the device models in the `lib/oxidized/model` sub-folder of the repository. For example, the Cisco IOS model, `ios.rb` may use the following prompt:

```text
  prompt /^([\w.@()-]+[#>]\s?)$/
```

Use IRB to verify if the prompt you've observed would match:

An example of a successful match:

```shell
# irb
irb(main):001:0> 'SEKRET-5A-X20#'.match /^([\w.@()-]+[#>]\s?)$/
=> #<MatchData "SEKRET-5A-X20#" 1:"SEKRET-5A-X20#">
irb(main):002:0>
```

An example of an unsuccessful match, for the prompt `$EKRET-5A-X20#` ($ used instead of capital S at the beginning of the prompt):

```shell
irb(main):002:0> '$EKRET-5A-X20#'.match /^([\w.@()-]+[#>]\s?)$/
=> nil
```

The prompt can then be adapted and re-tested, for example, by allowing the $ character as part of the prompt via `/^([\$\w.@()-]+[#>]\s?)$/`

```shell
irb(main):003:0> '$EKRET-5A-X20#'.match /^([\$\w.@()-]+[#>]\s?)$/
=> #<MatchData "$EKRET-5A-X20#" 1:"$EKRET-5A-X20#">
```

The new prompt now matches. You can copy the current model into the `~/.config/oxidized/` directory (keeping the original file name), and modify the prompt within the model file. After restarting Oxidized, the adapted model will be used.

*Troubleshooting an overly greedy prompt:*

Log in manually into the device. Use the same username and password or key configured for Oxidized. Execute the last command (which may be the first command to run) from which partial output is collected.

Compare the output to the partial output collected by Oxidized, focusing on the the difference that has been truncated. You can evaluate if this output could have matched the prompt regexp unexpectedly with IRB in a manner similar to the outlined in the previous section.

Adapt the prompt regexp to be more conservative if necessary in a local model override file.

*We encourage you to submit a PR for any prompt issues you encounter.*

## Building Models

Q) What are the steps required to build a model for a new device?

An Oxidized model, at minimum, requires just three elements:

- A model file, placed in the ~/.config/oxidized directory.
- A class defined within the file with the same name as the file that inherits from Oxidized::Model.
- At least one command that will be executed and the output of which will be collected.

A bare-bone example would be the file `~/.config/oxidized/launchinator.rb`, with the following context:

```ruby
class Launchinator < Oxidized::Model
  
  cmd 'show recent-launches'
```

This model will:

- Log into the device and expect the default prompt.
- Upon matching it, execute the command `show recent-launches`
- Collect the output.

It is often useful to, at minimum, define the following additional elements:

- A regexp for the prompt, via the `prompt` statement.
- A comment prefix, via the `comment` statement.
- A regexp for telnet username and password prompts.
- A mechanism for handling `enable` or similar functionality.

A more fleshed out example can be found by reviewing the `ios.rb` and `junos.rb` models.
