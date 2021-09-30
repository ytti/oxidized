class OpnSense < Oxidized::Model
  # minimum required permissions: "System: Shell account access"
  # must enable SSH and password-based SSH access

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

  cmd 'cat /conf/config.xml' do |cfg|
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    cfg
  end

  # The comment output has to be at the end since and XML file may not start
  # with a comment.

  # This gets the version using the opnsense-version command, or from the
  # /usr/local/opnsense/version/opnsense file for earlier versions of OPNsense
  # that lack the opnsense-version command. Newer versions of OPNsense no longer
  # store the version information in this file, so both versions have to be
  # supported here for now.
  cmd 'opnsense-version 2>/dev/null || echo "OPNsense "`cat /usr/local/opnsense/version/opnsense`' do |version|
    xmlcomment version
  end

  cfg :ssh do
    exec true
    pre_logout 'exit'
  end
end
