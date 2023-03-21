# frozen_string_literal: true

class ACOSA10 < Oxidized::Model # rubocop:todo Style/Documentation
  # A10 ACOS model for Thunder series  5.2.1

  #
  # NOTE: some password hashes are redacted due to being regenerated on each run
  #
  # adapted from acos.rb by jim@reptiles.org 

  comment '! '

  # ACOS prompt changes depending on the state of the device
  prompt(%r{^([-\w./:?\[\]()]+[#>]\s?)$})

  cmd :secret do |cfg|
    cfg.gsub!(/community read encrypted (\S+)/, 'community read encrypted <hidden>') # snmp
    cfg.gsub!(/secret encrypted (\S+)/, 'secret encrypted <hidden>') # tacacs-server
    cfg.gsub!(/password encrypted (\S+)/, 'password encrypted <hidden>') # user
    cfg
  end

  # scrub the datestamps and such, so that git doesn't diff them on each scrape
  cmd 'show version' do |cfg|
    cfg.gsub!(/\s(Last configuration saved at).*/, ' \\1 <removed>')
    cfg.gsub!(/\s(Memory).*/, ' \\1 <removed>')
    cfg.gsub!(/\s(Current time is).*/, ' \\1 <removed>')
    cfg.gsub!(/\s(The system has been up).*/, ' \\1 <removed>')
    lines = cfg.split(/\n+/)
    lines.pop
    lines = lines.join("\n")
    lines += "\n"
    comment lines
  end

  cmd 'show bootimage' do |cfg|
    lines = cfg.split(/\n+/)
    lines.pop
    lines = lines.join("\n")
    lines += "\n"
    comment lines
  end

  cmd 'show license' do |cfg|
    lines = cfg.split(/\n+/)
    lines.pop
    lines = lines.join("\n")
    lines += "\n"
    lines += "\n"
    comment lines
  end

  # scrub the datestamps and such, so that git doesn't diff them on each scrape
  cmd 'show running-config' do |cfg|
    cfg.gsub!(/(Current configuration).*/, '\\1 <removed>')
    cfg.gsub!(/(Configuration last updated at).*/, '\\1 <removed>')
    cfg.gsub!(/(Configuration last saved at).*/, '\\1 <removed>')
    cfg.gsub!(/(Configuration last synchronized at).*/, '\\1 <removed>')
    # scrub the passwords generated for snmp and harmony, so that git doesn't diff them on each scrape
    cfg.gsub!(/(password encrypted).*/, '\\1 <redacted>')
    cfg.gsub!(/(community read encrypted).*/, '\\1 <redacted>')
    cfg = cfg.split(/\n+/)
    cfg.pop
    cfg = cfg.join("\n")
    cfg += "\n"
    cfg
  end

  cmd 'show aflex' do |cfg|
    cfg += "\n"
    cfg = cfg.split(/\n+/)
    cfg.pop
    cfg = cfg.join("\n")
    cfg += "\n"
    comment cfg
  end

  # make a list of the aFlex scripts, and dump the script contents for each
  cmd 'show aflex' do |cfg|
    cfg.gsub!(/^Max aFlex.*/, '')
    cfg.gsub!(/^Name  .*/, '')
    cfg.gsub!(/^--*/, '')
    cfg.gsub!(/^Total aFlex.*/, '')
    cfg.gsub!(/^([^ ]*) .*/, '\\1')
    out = ''
    cfg.lines.each do |name|
      next unless name.length > 1 && ((name.strip != 'show') && !name.include?('#'))

      cmd("show aflex #{name.strip}") do |cfg2|
        content = cfg2.split(/Content:/).last.strip
        content = content.gsub(/\r/, '')
        lines = content.split(/\n+/)
        lines.pop
        lines.prepend("\n---- START aflex script #{name.strip}")
        lines.append("---- END aflex script #{name.strip}")
        lines = lines.join("\n")
        out += lines
      end
    end
    comment out
  end

  cfg :telnet do
    username(/login:/)
    password(/^Password:/)
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      pw = vars(:enable)
      pw ||= ''
      send "enable\r\n"
      cmd pw
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout "exit\nexit\nY\r\n"
  end
end
