class PfSense < Oxidized::Model
  # use other use than 'admin' user, 'admin' user cannot get ssh/exec. See issue #535

  def xmlcomment(str)
    # XML Comments start with <!-- and end with -->
    #
    # Because it's illegal for the first or last characters of a comment
    # to be a -, i.e. <!--- or ---> are illegal, and also to improve
    # readability, we add extra spaces after and before the beginning
    # and end of comment markers.
    #
    # Also, XML Comments must not contain --. So we put a space between
    # any double hyphens, by replacing any - that is followed by another -
    # with '- '
    data = ''
    str.each_line do |line|
      data << '<!-- ' << str.gsub(/-(?=-)/, '- ').chomp << " -->\n"
    end
    data
  end

  cmd :secret do |cfg|
    cfg.gsub! /(\s+<bcrypt-hash>).+?(<\/bcrypt-hash>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<password>).+?(<\/password>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<lighttpd_ls_password>).+?(<\/lighttpd_ls_password>)/, '\\1<secret hidden>\\2'
    cfg
  end

  cmd 'cat /cf/conf/config.xml' do |cfg|
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
