class PfSense < Oxidized::Model
  # use other use than 'admin' user, 'admin' user cannot get ssh/exec. See issue #535

  cmd :secret do |cfg|
    cfg.gsub! /(\s+<bcrypt-hash>).+?(<\/bcrypt-hash>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<password>).+?(<\/password>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<lighttpd_ls_password>).+?(<\/lighttpd_ls_password>)/, '\\1<secret hidden>\\2'
    cfg
  end

  cmd 'cat /cf/conf/config.xml' do |cfg|
    if not cfg.include? "<pfsense>" then
      raise "<pfsense> missing in config file!"
    end
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
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
