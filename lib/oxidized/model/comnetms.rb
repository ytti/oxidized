class ComnetMS < Oxidized::Model
  # Comnet Microsemi Switch
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg.gsub! /^[\r\n\s]*Building configuration\.\.\.\n/, ''
    cfg.gsub! /^end\n/, ''
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg.gsub! /^MEMORY\s*:.*\n/, ''
    cfg.gsub! /^FLASH\s*:.*\n/, ''
    cfg.gsub! /^Previous Restart\s*:.*\n/, ''
    cfg.gsub! /^System Time\s*:.*\n/, ''
    cfg.gsub! /^System Uptime\s*:.*\n/, ''
    comment cfg
  end

  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end
end
