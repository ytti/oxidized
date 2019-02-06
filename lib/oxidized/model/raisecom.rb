class RAISECOM < Oxidized::Model
  comment '! '
  prompt /([\w.@-]+[#>]\s?)$/

  cmd 'show version' do |cfg|
    cfg.gsub! /\s(System uptime is ).*/, ' \\1 <removed>'
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /\s(^radius-encrypt-key ).*/, ' \\1 <removed>'
    cfg
  end

  cfg :ssh do
    post_login 'terminal page-break disable'
    pre_logout 'exit'
  end
end
