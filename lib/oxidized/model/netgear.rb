class Netgear < Oxidized::Model

  comment '!'
  prompt /^(\([\w-]+\)\s[#>])$/

  expect /^--More-- or \(q\)uit/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  cfg :ssh do
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
    pre_logout 'quit'
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(!.*Time).*$/, '\1'
  end

end

