class EFOS < Oxidized::Model
  #Enhanced Fabric OS - Broadcom
  comment '! '
  prompt /^([\w.@()-]+[#>]\s?)$/

  cmd 'show bootvar' do |cfg|
    comment cfg
  end

  cmd 'show fiber-ports optical-transceiver-info all' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match(/System Up Time/) || line.match(/Current SNTP Synchronized Time:/) }.join
    cfg
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd 'enable'
      elsif vars(:enable)
        cmd 'enable', /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'logout'
  end
end