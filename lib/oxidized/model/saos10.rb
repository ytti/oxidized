class SAOS10 < Oxidized::Model
  using Refinements
  # Ciena SAOS switch
  # used for 10.x devices

  prompt /^[\w\-]+\*?> ?$/
  comment  '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd('show system hostname') { |cfg| comment cfg }

  cmd('show software') { |cfg| comment cfg }

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
    pre_logout 'exit'
  end
end
