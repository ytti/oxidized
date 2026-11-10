class Sofinet < Oxidized::Model
  # Sofinet SOFOS switches

  prompt /[#>]\s*$/
  comment '# '

  expect /---MORE---|--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.gsub!("\r", '')
    cfg.gsub!(/\e\[[0-9;]*m/, '')
    cfg.gsub!('---MORE---', '')
    cfg.gsub!('--More--', '')
    cfg.gsub!(/^ {13}/, '')
    cfg.gsub!(/^\s+\n/, '')
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub!(/(password\s+\d+\s+)\S+/, '\1<hidden>')
    cfg.gsub!(/(enable password\s+)\S+(\s+encrypt)/, '\1<hidden>\2')
    cfg.gsub!(/(wpa key\s+\d+\s+)\S+/, '\1<hidden>')
    cfg.gsub!(/(ap user admin password\s+\d+\s+)\S+/, '\1<hidden>')
    cfg.gsub!(/(key\s+\d+\s+)\S+/, '\1<hidden>')
    cfg.gsub!(/(crypto ike key\s+)\S+/, '\1<hidden>')
    cfg.gsub!(/(snmp-server community\s+)\S+/, '\1<hidden>')
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub!(/^System Uptime is .*\n/, '')
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub!(/^Building Configuration\.\.\.\s*\n(?:done\s*\n)?/i, '')
    cfg.gsub!(/^! Current configuration :.*\n/, '')
    cfg.gsub!(/^! Last configuration change at .*\n/, '')
    cfg.gsub!(/^! Flash config last updated at .*\n/, '')
    cfg
  end

  cfg :ssh do
    post_login do
      enable_val = vars(:enable).to_s

      if enable_val == 'true'
        send "enable\n"
        expect /[#>]\s*$/
      elsif enable_val != 'false' && !enable_val.empty?
        send "enable\n"
        expect /^[pP]assword:/
        send "#{enable_val}\n"
        expect /[#>]\s*$/
      end
    end

    pre_logout 'exit'
  end
end
