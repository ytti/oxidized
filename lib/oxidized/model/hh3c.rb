class HH3C < Oxidized::Model
    # HP 1910 switch

    prompt /^\r?(<[\w.@()-]+[#>]\s?)$/
    comment  '# '
  
    expect /^\s+---- More ----\s*$/ do |data, re|
        send ' '
        data.sub re, ''
    end

    cmd :all do |cfg|
      cfg.gsub! /\e\[16D\s+\e\[16D/, ''
      cfg
    end
  
    cmd :secret do |cfg|
      cfg.gsub! /^(\s*snmp-agent community).*/, '\\1 <configuration removed>'
      cfg.gsub! /^(password ).*/, '\\1<secret hidden>'
      cfg
    end

    cmd 'display version' do |cfg|
      cfg.gsub! /.*Uptime for this control.*/, ''
      cfg.gsub! /.*System restarted.*/, ''
      cfg.gsub! /uptime is\ .+/, '<uptime removed>'
      comment cfg
    end
  
    cmd 'display current-configuration' do |cfg|
      cfg = cfg.each_line.to_a[0..-1].join
      cfg
    end
  
    cfg :telnet, :ssh do
      username /User ?[nN]ame:/
      password /^\r?Password:/
      post_login do
        cmd '_cmdline-mode on', /All commands can be displayed and executed/
        cmd 'Y', /input password:/
        cmd '512900'
      end
      pre_logout 'quit'
    end
  end
  