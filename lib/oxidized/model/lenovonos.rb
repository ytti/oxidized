class LenovoNOS < Oxidized::Model
  using Refinements

  prompt /^([\w.@()-]+[#>]\s?)$/
  comment '! '

  def comment_ext(header, output)
    data = ''
    data << header
    data << "\n"
    data << output
    data << "\n"
    comment data
  end

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(enable password) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(access user \S+ password) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(snmp-server \S+-community) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(tacacs-server \S+ \S+ ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(ntp message-digest-key \S+ md5-ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
    cfg
  end

  expect /^Select Command Line Interface mode.*iscli.*:/ do |data, re|
    send "iscli\n"
    data.sub re, ''
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.to_a

    cfg = cfg.reject { |line| line.match /^System Information at/ }
    cfg = cfg.reject { |line| line.match /^Switch has been up for/ }
    cfg = cfg.reject { |line| line.match /^Last boot:/ }
    cfg = cfg.reject { |line| line.match /^Temperature / }
    cfg = cfg.reject { |line| line.match /^Power Consumption/ }
    cfg = cfg.reject { |line| line.match /^Fan/ }

    cfg = cfg.join
    comment_ext("=== show version ===", cfg)
  end

  cmd 'show boot' do |cfg|
    comment_ext("=== show boot ===", cfg)
  end

  cmd 'show transceiver' do |cfg|
    comment_ext("=== show transceiver ===", cfg)
  end

  cmd 'show software-key' do |cfg|
    comment_ext("=== show software-key ===", cfg)
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Current configuration:[^\n]*\n/, ''
    if vars(:remove_unstable_lines) == true
      cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
      cfg.gsub! /(.* administrator-password )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
      cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
    end
    cfg
  end

  cfg :ssh do
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal-length 0'
    pre_logout 'exit'
  end
end
