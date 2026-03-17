class Exalink < Oxidized::Model
  using Refinements

  PROMPT = /^([\w.@()-]+[#>]\s?)$/

  prompt PROMPT
  comment '! '

  def filter(cfg)
    cfg.gsub! /\r\n?/, "\n"
    cfg.gsub! PROMPT, ''
  end

  cmd 'show version' do |cfg|
    cfg = filter cfg
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime/i) }
    comment cfg.join
  end

  cmd 'show port' do |cfg|
    cfg = filter cfg
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = filter cfg
    cfg.gsub! /^(show run.*)$/, '! \1'
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    cfg.gsub! /^[\w.@_()-]+[#].*$/, ''
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
