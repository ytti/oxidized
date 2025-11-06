class OpnSense < Oxidized::Model
  using Refinements

  # minimum required permissions: "System: Shell account access"
  # must enable SSH and password-based SSH access

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
  cmd 'opnsense-version || echo "OPNsense "`cat /usr/local/opnsense/version/opnsense`' do |version|
    xmlcomment version
  end

  metadata :bottom do
    xmlcomment interpolate_string(
      vars("metadata_bottom") ||
      vars("metadata_top") ||
      Oxidized::Model::METADATA_DEFAULT
    )
  end

  cfg :ssh do
    exec true
    pre_logout 'exit'
  end
end
