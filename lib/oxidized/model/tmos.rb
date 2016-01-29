class TMOS < Oxidized::Model

  comment  '# '

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/passphrase (\S+)/, 'passphrase <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg.gsub!(/community-name (\S+)/, 'community-name <secret removed>')
    cfg
  end

  cmd('tmsh show sys version') { |cfg| comment cfg }

  cmd('tmsh show sys software') { |cfg| comment cfg }

  cmd 'tmsh show sys hardware field-fmt' do |cfg|
    cfg.gsub!(/fan-speed (\S+)/, '')
    cfg.gsub!(/temperature (\S+)/, '')
    comment cfg
  end

  cmd('cat /config/bigip.license') { |cfg| comment cfg }

  cmd 'tmsh list' do |cfg|
    cfg.gsub!(/state (up|down)/, '')
    cfg.gsub!(/errors (\d+)/, '')
    cfg
  end

  cmd('tmsh list net route all') { |cfg| comment cfg }

  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.crt') { |cfg| comment cfg }

  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.key') { |cfg| comment cfg }

  cmd 'tmsh show running-config sys db all-properties' do |cfg|
    cfg.gsub!(/sys db configsync.localconfigtime {[^}]+}/m, '')
    cfg.gsub!(/sys db gtm.configtime {[^}]+}/m, '')
    cfg.gsub!(/sys db ltm.configtime {[^}]+}/m, '')
    comment cfg
  end

  cfg :ssh do
    exec true  # don't run shell, run each command in exec channel
  end

end
