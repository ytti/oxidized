class OpenGear < Oxidized::Model
  using Refinements

  comment '# '

  prompt /^(\$\s)$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg.gsub!(/community=(\S+)/, 'community=<secret removed>')
    cfg.gsub!(/private_key=(\S+)/, 'private_key=<secret removed>')
    cfg.gsub!(/ key=(\S+)/, ' key=<secret removed>')
    cfg.gsub!(/hashed_password=(\S+)/, 'hashed_password=<secret removed>')
    cfg
  end

  cmd 'cat /etc/version' do |cfg|
      cfg.gsub! /^/, 'OS Version: '
      comment cfg
  end

  # newer opengear firmware versions
  cmd 'ogdeviceinfo -r' do |cfg|
    if not cfg.include? "ogdeviceinfo: command not found"
      comment cfg
    end
  end

  cmd 'config export' do |cfg|
    if not cfg.include? "usage: config"
      out = ''
      cfg.each_line do |line|
        out << line
      end
      out
    end
  end

  # older opengear firmware versions
  cmd 'showserial' do |cfg|
    if not cfg.include? "showserial: command not found"
      cfg.gsub! /^/, 'Serial Number: '
      comment cfg
    end
  end

  cmd 'config -g config' do |cfg|
    if not cfg.include? "config: error: argument"
      out = ''
      cfg.each_line do |line|
        out << line
      end
      out
    end
  end

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
