class WEOS < Oxidized::Model
  # Westell WEOS, works with Westell 8178G, Westell 8266G

  prompt /^(\s[\w.@-]+[#>]\s?)$/

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :telnet do
    username /login:/
    password /assword:/
    post_login 'cli more disable'
    pre_logout 'logout'
  end
end
