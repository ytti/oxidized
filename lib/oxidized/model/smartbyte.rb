class SmartByte < Oxidized::Model
  using Refinements

  comment '! '

  cmd :secret do |cfg|
    cfg.gsub!(/group (\S+) v2c/, 'group <hidden> v2c')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[0..-2].join
  end

  cmd 'show running-config'

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show interface optical-transceiver info' do |cfg|
    cfg.gsub! /^\|Transceiver current alarm information:           \|\s+\+-------------------------------------------------\+.*?\s+\+-------------------------------------------------\+\s+/m, ''
    comment cfg
  end

  cmd 'show power' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^.*? login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end

    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
