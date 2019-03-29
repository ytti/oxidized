# Cisco switch 

### To add the feature to list unsaved changes done on a switch.
Create the file
```text
~/.config/oxidized/model/ios.rb
```

Add this
```text
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

Back to [Model-Notes](README.md)
