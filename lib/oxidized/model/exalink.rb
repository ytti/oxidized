class Exalink < Oxidized::Model
  using Refinements

  prompt /^([\w.@()-]+[#>]\s?)$/
  comment '! '

  cmd :all do |cfg|
    cfg.gsub! /\r\n?/, "\n"
    cfg.cut_both
  end

  cmd 'show version' do |cfg|
    comment cfg.reject_lines /uptime/i
  end

  cmd 'show port' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(show run.*)$/, '! \1'
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'logout'
  end
end
