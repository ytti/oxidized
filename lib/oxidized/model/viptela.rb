class Viptela < Oxidized::Model
  # Cisco Vipetla

  prompt /[-\w]+#\s$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /(^\s+secret-key|password|auth-password|priv-password)\s+.*$/, '\\1 <secret hidden>'
    cfg.gsub! /(^\s+community)\s.*$/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cfg :ssh do
    post_login 'paginate false'
    pre_logout 'exit'
  end
end
