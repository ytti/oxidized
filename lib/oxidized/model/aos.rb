class AOS < Oxidized::Model
  # Alcatel-Lucent Operating System
  # used in OmniSwitch

  comment  '! '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show system' do |cfg|
    cfg = cfg.each_line.find { |line| line.match 'Description' }
    comment cfg.to_s.strip
  end

  cmd 'show chassis' do |cfg|
    comment cfg
  end

  cmd 'show hardware info' do |cfg|
    comment cfg
  end

  cmd 'show license info' do |cfg|
    comment cfg
  end

  cmd 'show license file' do |cfg|
    comment cfg
  end

  cmd 'show configuration snapshot' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^login : /
    password /^password : /
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
