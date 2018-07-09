class Hpvc < Oxidized::Model
  # HPE Moonshot Switch / HP Virtual Connect Linux 

  # sometimes the prompt might have a leading nul or trailing ASCII Bell (^G)
  prompt /^\0*(\([\w.-]+\)).?[>#]$/
  comment '# '

  cfg :telnet, :ssh do
    post_login 'enable'
    post_login 'terminal length 0'

    pre_logout "exit\nquit\n"

  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^\!System Up Time .*$/, '\\1 <removed>'
    cfg.gsub /^\s+/, ''
  end

end
