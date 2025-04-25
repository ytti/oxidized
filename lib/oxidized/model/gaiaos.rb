class GaiaOS < Oxidized::Model
  using Refinements

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

  # check for vsx / multiple context
  cmd 'show vsx' do |cfg|
    @is_vsx = cfg.include? 'VSX Enabled'
    logger.debug cfg
  end

  cmd 'show asset all' do |cfg|
    comment cfg
  end

  cmd 'show version all' do |cfg|
    comment cfg
  end

  post do
    if @is_vsx
      multiple_context
    else
      single_context
    end
  end

  def single_context
    logger.debug 'Single context tasks'
    cmd 'show configuration' do |cfg|
      cfg.gsub! /^# Exported by \S+ on .*/, '# '
      cfg
    end
  end

  def multiple_context
    logger.debug 'Multi context tasks'
    cmd 'show virtual-system all' do |systems|
      vs_items = systems.scan(/^(?<VSID>\d+)\s+(?<VSNAME>.*[^\s])/)
      allcfg = ''
      vs_items.each do |item|
        allcfg += "\n\n\n#--------======== [ VS #{item[0]} - #{item[1]} ] ========--------\n\n"
        allcfg += "set virtual-system #{item[0]}\n\n"
        cmd "set virtual-system #{item[0]}" do |vs|
          logger.debug vs
          cmd 'show configuration' do |vscfg|
            vscfg.gsub! /^# Exported by \S+ on .*/, '# '
            allcfg += vscfg
          end
        end
      end
      allcfg
    end
  end

  cfg :ssh do
    # User shell must be /etc/cli.sh
    post_login 'set clienv rows 0'
    pre_logout 'exit'
  end
end
