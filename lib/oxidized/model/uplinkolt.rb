class UPLINKOLT < Oxidized::Model
  prompt /^([\w.@()-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.gsub!(/^show running-config$/, '')
    cfg.gsub!(/^.*\s*#\s*$/, '')
    # Remove leading and trailing whitespace
    cfg.strip!
    # Remove empty lines
    cfg.gsub!(/^\s*$/, '')
    cfg
  end

  cmd 'configure terminal' do
    # Enter configure terminal mode
    cmd 'show version' do |cfg|
      cfg.gsub! /^show version/, ''
      comment cfg
    end
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Current configuration:/, ''
    cfg
  end

  cfg :telnet, :ssh do
    username /^Login:/i
    password /^Password:/i
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'disable'
    pre_logout 'exit'
  end
end
