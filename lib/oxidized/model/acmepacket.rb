class ACMEPACKET < Oxidized::Model
  # Oracle ACME Packet 3k, 4k, 6k series

  prompt /^\r*([\w.@()-\/]+[#>]\s?)$/

  comment  '! '

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :telnet do
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
