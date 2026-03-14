class BDCOM < Oxidized::Model
  using Refinements

  comment '! '

  cmd :secret do |cfg|
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[0..-2].join
  end

  cmd 'show running-config'

  cmd 'show version' do |cfg|
    cfg.gsub! /(\s*uptime is\s*)[0-9:]+/, '\1 <removed>'
    cfg.gsub! /(\s*current time:\s*)[0-9-]+\s+[0-9:]+/, '\1 <removed>'
    cfg.gsub! /(\s*at)\s+[0-9-]+\s+[0-9:]+(,\s*uptime\s+[0-9:]+)?/, '\1 <removed>'
    comment cfg
  end

  cmd 'show power-status' do |cfg|
    comment cfg
  end

  cmd 'show fan-status' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end

    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
