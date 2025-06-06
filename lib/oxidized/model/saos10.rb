class SAOS10 < Oxidized::Model
  # Ciena SAOS switch
  # used for 10.x devices

  comment  '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  # cmd 'show system hostname' do |cfg|
  #  @hostname = Regexp.last_match(1) if cfg =~ /^| Hostname | (\S+) |/
  #  comment cfg
  # end

  cmd('show system hostname') { |cfg| comment cfg }

  cmd('show system components') { |cfg| comment cfg }

  cmd('show system health') { |cfg| comment cfg }

  cmd('show system last-reset-reasons') { |cfg| comment cfg }

  cmd 'show running config' do |cfg|
    cfg.gsub! /^! Created: [^\n]*\n/, ''
    cfg.gsub! /^! On terminal: [^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /login:/
    password /assword:/
  end

  cfg :telnet, :ssh do
    post_login 'set session more off'
    #post_login 'system shell set more off'
    #post_login 'system shell session set more off'
    pre_logout 'exit'
  end
end
