class Netgear < Oxidized::Model

  comment '!'
  prompt /^(\([\w-]+\)\s[#>])$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        cmd 'enable'
        # Interpret enable: true as meaning we won't be prompted for a password
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          cmd vars(:enable) + "\n"
        end
        expect /^.+[#]$/
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'quit'
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(!.*Time).*$/, '\1'
  end

end
