class FTOS < Oxidized::Model
  # Force10 FTOS model #

  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /(secret \d* {0,1})\S+(.*)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(password \d+) \S+(.*)/, '\\1 <hash hidden>\\2'
    cfg.gsub! /(^snmp-server.*version \S+) \S+(.*)/, '\\1 <community removed>\\2'
    cfg.gsub! /(^radius-server.*key \d )\S+/, '\\1<hash hidden>\\2'
    cfg
  end

  cmd 'show inventory' do |cfg|
    # Old versions of FTOS can occasionally return data that triggers encoding errors.
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace, replace: "")
    comment cfg
  end

  cmd 'show inventory media' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    pre_logout 'exit'
  end
end
