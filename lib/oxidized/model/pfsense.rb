class PfSense < Oxidized::Model
  using Refinements

  # use other use than 'admin' user, 'admin' user cannot get ssh/exec. See issue #535

  cmd :secret do |cfg|
    cfg.gsub! /(\s+<bcrypt-hash>).+?(<\/bcrypt-hash>)/, '\\1[secret hidden]\\2'
    cfg.gsub! /(\s+<password>).+?(<\/password>)/, '\\1[secret hidden]\\2'
    cfg.gsub! /(\s+<lighttpd_ls_password>).+?(<\/lighttpd_ls_password>)/, '\\1[secret hidden]\\2'
    cfg
  end

  cmd 'cat /cf/conf/config.xml' do |cfg|
    raise "<pfsense> missing in config file!" unless cfg.include? "<pfsense>"

    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    cfg.gsub! /\s<created>\s*<time>\d*<\/time>\s*.*CDATA\[Auto\].*\s*.*\s*<\/created>/, ''
    cfg
  end

  # The comment output has to be at the end since and XML file may not start
  # with a comment.

  cmd 'cat /etc/version' do |version|
    xmlcomment "PFsense #{version}"
  end

  cfg :ssh do
    exec true
    pre_logout 'exit'
  end
end
