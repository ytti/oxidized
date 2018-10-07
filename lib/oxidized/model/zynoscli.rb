class ZyNOSCLI < Oxidized::Model
  # Used in Zyxel DSLAMs, such as SAM1316

  # Typical prompt "XGS4600#"
  prompt /^([\w.@()-]+[#>]\s\e7)$/
  comment  ';; '

  cmd :all do |cfg|
    cfg.gsub! /^.*\e7/, ''
  end
  cmd 'show stacking'

  cmd 'show version'

  cmd 'show running-config'

  cfg :telnet do
    username /^User name:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        # Interpret enable: true as meaning we won't be prompted for a password
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        expect /^.+[#]$/
      end
    end
    pre_logout 'exit'
  end
end
