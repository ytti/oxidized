class OpenGear < Oxidized::Model
  comment '# '

  prompt /^(\$\s)$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg
  end

  cmd('cat /etc/version') { |cfg| comment cfg }

  cmd('config -g config') { |cfg| cfg }

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
