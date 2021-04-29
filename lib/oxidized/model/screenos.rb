class ScreenOS < Oxidized::Model
  # Netscreen ScreenOS model #

  comment '! '

  prompt /^[\w.:()-]+->\s?$/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(set admin name) .*|^(set admin password) .*/, '\\1 <removed>'
    cfg.gsub! /^(set admin user .* password) .* (.*)/, '\\1 <removed> \\2'
    cfg.gsub! /(secret|password|preshare) .*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'get system' do |cfg|
    cfg.gsub! /^Date .*\n/, ''
    cfg.gsub! /^Up .*\n/, ''
    cfg.gsub! /(current bw ).*/, '\\1 <removed>'
    comment cfg
  end

  cmd 'get config' do |cfg|
    cfg.each_line.to_a[1..-1].join
  end

  cfg :telnet do
    username '/^login:/'
    password '/^password:/'
  end

  cfg :telnet, :ssh do
    post_login 'set console page 0'
    pre_logout do
      send "exit\n"
      send "n"
    end
  end
end
