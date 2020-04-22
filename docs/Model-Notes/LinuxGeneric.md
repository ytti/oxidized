# LinuxGeneric model notes

To expand the usage of this model for more specific needs you can create a file in `~/.config/oxidized/model/linuxgeneric.rb`

```ruby
require 'oxidized/model/linuxgeneric.rb'

class LinuxGeneric
  
  cmd :secret, clear: true do |cfg|
    cfg.gsub! /^(default (\S+).* (expires) ).*/, '\\1 <redacted>'
    cfg
  end

  post do
    cfg = add_comment 'THE MONKEY PATCH'
    cfg += cmd 'firewall-cmd --list-all --zone=public'
  end
end
```

See [Extending-Model](https://github.com/ytti/oxidized/blob/master/docs/Creating-Models.md#creating-and-extending-models)

Back to [Model-Notes](README.md)
