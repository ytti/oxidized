class OpenGear < Oxidized::Model

  comment  '# '

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg
  end

  cmd('cat /etc/version') { |cfg| comment cfg }

  cmd 'config -g config'

  cfg :ssh do
    exec true unless vars :ssh_no_exec  # don't run shell, run each command in exec channel
  end

end
