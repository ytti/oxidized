class SAOS < Oxidized::Model
  using Refinements

  # Ciena SAOS switch
  # used for 6.x devices

  comment '! '
  prompt /^[\w-]+\*?>\s?/

  cmd :all do |cfg|
    cfg.gsub! /(Waiting for )(accounting|authorization).*\n/, '' # Remove TACACS errors
    cfg.cut_both
  end

  cmd 'chassis show device-id power' do |cfg|
    comment cfg
  end

  cmd 'software show' do |cfg|
    cfg.gsub! /^\| Bank status.*/, '| Bank status         : <removed>                                              |'
    comment cfg
  end

  cmd 'port xcvr show' do |cfg|
    cfg.gsub! /^SHELL PARSER FAILURE.*/, '' # Ignore command failure
    cfg.gsub! /(\s\|.{10}\|)(Ena\s\s|\s\sDis|UCTF\s)(.*)/, '\1     \3' # Remove transient operational state
    comment cfg
  end

  cmd 'configuration show' do |cfg|
    cfg.gsub! /^! Created: [^\n]*\n/, ''
    cfg.gsub! /^! On terminal: [^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /login:/
    password /assword:/
  end

  cfg :telnet, :ssh do
    post_login 'system shell set more off'
    post_login 'system shell session set more off'
    pre_logout 'exit'
  end
end
