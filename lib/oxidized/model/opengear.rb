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

  cmd 'showserial' do |cfg|
    cfg.gsub! /^/, 'Serial Number: '
    comment cfg
  end

  cmd 'config -g config' do |cfg|
    out=''
    cfg.each_line do |line|
      out << line
    end
   out
  end

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
