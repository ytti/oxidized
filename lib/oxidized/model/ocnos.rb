class OcNOS < Oxidized::Model
  using Refinements

  prompt /([\w.@-]+[#>]\s?)$/
  comment '# '

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout do
      send "disable\r"
      send "logout\r"
    end
  end

  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system fru' do |cfg|
    comment cfg
  end

  cmd 'show system-information board-info' do |cfg|
    comment cfg
  end

  cmd 'show forwarding profile limit' do |cfg|
    comment cfg
  end

  cmd 'show license' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end
end
