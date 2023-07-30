class OpenGear < Oxidized::Model
  using Refinements

  comment '# '

  prompt /^(\$\s)$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg
  end

  cmd('cat /etc/version') { |cfg| comment cfg }

  cmd('config -g config 2>/dev/null') { |cfg| cfg }
  cmd('ogcli e 2>/dev/null') { |cfg| cfg }

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
