class IBM < Oxidized::Model

  prompt /^(([\w.@()-]+[#>]\s?))$/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server \S+community) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server user \S+ \S+ \S+ \S+-password) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(access user \S+ password) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server \S+host \S+ ekey) (\S+)/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comments = []
    comments << cfg.lines.first
    lines = cfg.lines
    lines.each_with_index do |line,i|
        if line.match /^Software Version\s+(.+)\s+\(FLASH (.+)\).*/
            comments << "Software: #{$1}, Booted from: #{$2}"
        end

        if line.match /^Boot kernel version (.+)/
            comments << "Boot Kernel Version: #{$1}"
        end
        if line.match /^Switch Serial No: (.+)/
            comments << "Serial Number: #{$1}"
        end
    end
    comments << "\n"
    comment comments.join "\n"
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^Current configuration: [^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal-length 0'
    pre_logout 'exit'
  end

end
