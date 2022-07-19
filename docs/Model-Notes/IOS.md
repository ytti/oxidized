# Cisco IOS Switches

## Include unsaved changes done on a device (commented) with each configuration

Create the file `~/.config/oxidized/model/ios.rb` with the following contents to extend the IOS model:

```ruby
require 'oxidized/model/ios.rb'

class IOS

  cmd 'show archive config diff' do |cfg|
    # Print diff unless ntp period change or ssl-cert read from file
    cfg.gsub! /^\n/, '' # Remove empty line
    cfg.gsub! /^!\n/, '' # Remove line with only !
    cfg.gsub! /.*ntp clock-period \d+\n/, '' # Remove line with only "ntp clock-period blabla"
    cfg.gsub! /\n/, "\\n" # Escape newline
    cfg.gsub! /crypto pki certificate chain.*certificate .*\.cer\\n/, '' # Remove ssl-cert in start config, as it is read from file, this always differ in running if used.
    cfg.gsub! /crypto pki certificate chain.*-\s*quit\\n/, '' # Remove ssl-cert from running
    cfg.gsub! /\\n/, "\n" # Set newline back
    unless cfg == "!Contextual Config Diffs:\n" # Do not print if only something above was changed
      comment cfg
    end
  end

end
```

## Support Lower Privilege Level (Readonly RBAC) User Accounts

If Oxidized is configured to use a lower privilege level (readonly) local
account, it may be necessary for it to run "show running-config view full"
instead of "show running-config". In these cases, the ```ios_rbac: true```
variable needs to be set either as a top-level variable or at the groups
level.

Below is are examples showing how this can be enabled in the oxidized config:

### Top Level Variable

```yaml
vars:
  ios_rbac: true
```

### Group Level Variable

```yaml
groups:
  cisco:
    vars:
      ios_rbac: true
source:
  default: csv
  csv:
    file: /home/oxidized/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      ip: 1
      model: 2
      group: 2
```

Back to [Model-Notes](README.md)
