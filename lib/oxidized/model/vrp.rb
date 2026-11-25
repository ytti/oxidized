class VRP < Oxidized::Model
  using Refinements

  # Huawei VRP

  prompt /^.*(<[\w.-]+>)$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /(pin verify (?:auto|)).*/, '\\1 <PIN hidden>'
    cfg.gsub! /(%\^%#.*%\^%#)/, '<secret hidden>'
    cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :significant_changes do |cfg|
    cfg.reject_lines [/^!Last configuration was (updated|saved) at /]
  end

  cfg :telnet do
    username /^Username:$/
    password /^Password:$/
  end

  cfg :telnet, :ssh do
    post_login 'screen-length 0 temporary'
    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    comment cfg.reject_lines [
      /uptime/,
      /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/
    ]
  end

  cmd 'display device' do |cfg|
    comment cfg.reject_lines [
      /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/
    ]
  end

  cmd 'display current-configuration all' do |cfg|
    cfg.reject_lines [
      /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/
    ]
  end
end
