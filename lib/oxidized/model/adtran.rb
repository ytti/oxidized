class Adtran < Oxidized::Model
  # Adtran

  prompt /([\w.@-]+[#>]\s?)$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  cmd 'show running-config'

  cfg :ssh do
    post_login do
      send "enable\n"
      cmd vars(:enable)
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    sleep 1
  end
end
