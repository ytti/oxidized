class Aoscx < Oxidized::Model
  # HP ArubaOS-CX (AOS-CX) model for Oxidized
  # Tested on CX 6200, 6300, 6400, and 8400 series switches

  prompt /^([\w.-]+# )$/
  comment '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub!(/^(snmp-server community) .+/, '\\1 <hidden>')
    cfg.gsub!(/^(radius-server key) .+/, '\\1 <hidden>')
    cfg.gsub!(/^(tacacs-server key) .+/, '\\1 <hidden>')
    cfg.gsub!(/^(password manager) .+/, '\\1 <hidden>')
    cfg.gsub!(/^(password) .+/, '\\1 <hidden>')
    cfg.gsub!(/(user-password encrypted) .+/, '\\1 <hidden>')
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cmd 'show environment temperature' do |cfg|
    comment cfg
  end

  cmd 'show environment fan' do |cfg|
    comment cfg
  end

  cmd 'show environment power-supply' do |cfg|
    comment cfg
  end

  cmd 'show system power-supply' do |cfg|
    comment cfg
  end

  cmd 'show interface transceiver details' do |cfg|
    comment cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end

  pre do
    cmds = [
      'show environment power-supply input-voltage',
      'show environment power-consumption',
      'show system power-supply input-voltage',
      'show system power-consumption'
    ]
    cmds.each do |cmd|
      run_cmd(cmd)
    end
  end

  cmd :all do |cfg|
    cfg.gsub!(
      /^\s*show environment power-supply input-voltage.*?(?=^\s*show\s|\Z)/mi,
      ''
    )
    cfg.gsub!(
      /^\s*show environment power-consumption.*?(?=^\s*show\s|\Z)/mi,
      ''
    )
    cfg.gsub!(
      /^\s*Input Voltage Averaging Period\s*:.*?(?=^\s*\S|\Z)/mi,
      ''
    )
    cfg.gsub!(
      /^\s*Power Consumption Averaging Period\s*:.*?(?=^\s*\S|\Z)/mi,
      ''
    )
    cfg
  end

  cmd :all do |section|
    section.gsub(/(\s)-?\d+(?:\.\d+)?\s*[CF]\b/i, '\1<hidden>')
  end

  cmd :all do |section|
    s = section.dup
    s.gsub!(/^(.+uptime is).+$/, '\\1 <hidden>')
    s.gsub!(/^(.+temperature is).+$/, '\\1 <hidden>')
    s
  end
end