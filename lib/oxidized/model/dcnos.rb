# DCNOS is a ZebOS derivative by DCN (http://www.dcnglobal.com/)
# In addition to products by DCN (now Yunke China), this OS type
# powers a number of re-branded OEM devices.

# Developed against SNR S2950-24G 7.0.3.5

class DCNOS < Oxidized::Model
  comment '! '

  cmd :all do |cfg|
    cfg.cut_head
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /\s(Uptime is).*/, ''
    comment cfg
  end

  cmd 'show boot-files' do |cfg|
    comment cfg
  end

  cmd 'show flash' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^login:/i
    password /^password:/i
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
