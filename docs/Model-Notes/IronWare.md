# IronWare Ruckus ICX Switches 

Tested on ICX 7150 09.0.10h_cd2 and 09.0.10f

The 09 series firmware does not allow entering directly into privileged exec mode and requires a username and password to elevate.  


## config changes

Add a variable called enableuser

```yaml
vars: {
enable: 'yourenablepassword',
enableuser: 'yourenableusername'
}
```

Create the file ironware.rb and place in your local models directory

```bash
/home/oxidized/.config/oxidized/model
```

ironware.rb

```ruby
require 'oxidized/model/ironware'
class IronWare
  using Refinements

  # handle pager with enable
  # Clear previous block
  cfg :telnet, :ssh, clear: true do
    if vars :enable
      if vars(:enable).is_a? TrueClass
        post_login 'enable'
      # set enable to use username and password
      else
        post_login do
          send "enable\r\n"
          # enable password from config
          pw = vars(:enable)
          # new var in config enableuser
          user = vars(:enableuser)
          user += "\r"

          send user
          expect(/\s+[pP]assword:$/)
          cmd pw
        end
      end
    end
    post_login ''
    post_login 'skip-page-display'
    pre_logout "logout\nexit\nexit\n"
  end
end

```
