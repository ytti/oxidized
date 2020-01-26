class EOS < Oxidized::Model
  # Arista EOS model #

  prompt /^.+[#>]\s?$/

  comment  '! '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable secret).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server key \d+).*/, '\\1 <configuration removed>'
    cfg.gsub! /( {6}key) (\h+ 7) (\h+).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show inventory | no-more' do |cfg|
    comment cfg
  end

  cmd 'show running-config | no-more | exclude ! Time:' do |cfg|
    cfg
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
        expect /^.+[#>]\s?$/
      end
      post_login 'terminal length 0'
    end
    pre_logout 'exit'
  end
end
