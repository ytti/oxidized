class GaiaOS < Oxidized::Model
  # CheckPoint - Gaia OS Model

  # Gaia Prompt
  prompt /^([\[\]\w.@:-]+[#>]\s?)$/

  # Comment tag
  comment  '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(set expert-password-hash ).*/, '\1<EXPERT PASSWORD REMOVED>'
    cfg.gsub! /^(set user \S+ password-hash ).*/, '\1<USER PASSWORD REMOVED>'
    cfg.gsub! /^(set ospf .* secret ).*/, '\1<OSPF KEY REMOVED>'
    cfg.gsub! /^(set snmp community )(.*)( read-only.*)/, '\1<SNMP COMMUNITY REMOVED>\3'
    cfg.gsub! /^(add snmp .* community )(.*)(\S?.*)/, '\1<SNMP COMMUNITY REMOVED>\3'
    cfg.gsub! /(auth|privacy)(-pass-phrase-hashed )(\S*)/, '\1-pass-phrase-hashed <SNMP PASS-PHRASE REMOVED>'
    cfg
  end

  cmd 'show asset all' do |cfg|
    comment cfg
  end

  cmd 'show version all' do |cfg|
    comment cfg
  end

  cmd 'show configuration' do |cfg|
    cfg.gsub! /^# Exported by \S+ on .*/, '# '
    cfg
  end

  cfg :ssh do
    # User shell must be /etc/cli.sh
    post_login 'set clienv rows 0'
    pre_logout 'exit'
  end
end
