class Catos < Oxidized::Model
  prompt /^[\w.@-]+>\s?(\(enable\) )?$/
  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show system' do |cfg|
    cfg = cfg.gsub /(\s+)\d+,\d+:\d+:\d+(\s+)/, '\1X\2'
    comment cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.gsub /\d+(K)/, 'X\1'
    cfg = cfg.gsub /^(Uptime is ).*/, '\1X'
    comment cfg
  end

  cmd 'show conf all' do |cfg|
    cfg = cfg.sub /^(#time: ).*/, '\1X'
    cfg.each_line.drop_while { |line| not line.match /^begin/ }.join
  end

  cfg :telnet do
    username /^Username: /
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'set length 0'
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
