class TMOS < Oxidized::Model
  using Refinements

  # Use this model if you have AAA configured in tmos
  # See https://github.com/ytti/oxidized/issues/437
  # F5 KB: https://my.f5.com/manage/s/article/K28660000

  comment '# '

  cmd :secret do |cfg|
    cfg.gsub!(/^([\s\t]*)secret \S+/, '\1secret <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)password \S+/, '\1password <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)passphrase \S+/, '\1passphrase <secret removed>')
    cfg.gsub!(/community \S+/, 'community <secret removed>')
    cfg.gsub!(/community-name \S+/, 'community-name <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)encrypted \S+$/, '\1encrypted <secret removed>')
    cfg
  end

  cmd('run /util bash -c "tmsh -q show sys version"') { |cfg| comment cfg }

  cmd('run /util bash -c "tmsh -q show sys software"') { |cfg| comment cfg }

  cmd 'run /util bash -c "tmsh -q show sys hardware field-fmt"' do |cfg|
    cfg.gsub!(/fan-speed (\S+)/, '')
    cfg.gsub!(/temperature (\S+)/, '')
    cfg.gsub!(/humidity (\S+)/, '')
    comment cfg
  end

  cmd('run /util bash -c "cat /config/bigip.license"') { |cfg| comment cfg }

  cmd 'run /util bash -c "tmsh -q list"' do |cfg|
    cfg.gsub!(/state (up|down|checking|irule-down)/, '')
    cfg.gsub!(/errors (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-bps (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-cps (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-pps (\d+)\n/, '')
    cfg.gsub!(/^\s*\S*encrypted \S+\n/, '')
    cfg
  end

  cmd('run /util bash -c "tmsh -q list net route all"') { |cfg| comment cfg }

  cmd('run /util bash -c "/bin/ls --full-time --color=never /config/ssl/ssl.crt"') { |cfg| comment cfg }

  cmd('run /util bash -c "/bin/ls --full-time --color=never /config/ssl/ssl.key"') { |cfg| comment cfg }

  cmd 'run /util bash -c "tmsh -q show running-config sys db all-properties"' do |cfg|
    cfg.gsub!(/sys db configsync.localconfigtime {[^}]+}/m, '')
    cfg.gsub!(/sys db gtm.configtime {[^}]+}/m, '')
    cfg.gsub!(/sys db ltm.configtime {[^}]+}/m, '')
    comment cfg
  end

  cmd('run /util bash -c "[ -d "/config/zebos" ] && cat /config/zebos/*/ZebOS.conf"') { |cfg| comment cfg }

  cmd('run /util bash -c "cat /config/partitions/*/bigip*.conf"') { |cfg| comment cfg }

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
