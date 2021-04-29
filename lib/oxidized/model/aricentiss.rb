# Developed against:
# #show version
# Switch ID       Hardware Version                Firmware Version
# 0               SSE-G48-TG4   (P2-01)           1.0.16-9

class AricentISS < Oxidized::Model
  prompt /^(\e\[27m)?[ \r]*[\w-]+# ?$/

  cfg :ssh do
    # "pagination" was misspelled in some (earlier) versions (at least 1.0.16-9)
    # 1.0.18-15 is known to include the corrected spelling
    post_login 'no cli pagination'
    post_login 'no cli pagignation'
    pre_logout 'exit'
  end

  cmd :all do |cfg|
    # * Drop first line that contains the command, and the last line that
    #   contains a prompt
    # * Strip carriage returns
    cfg.delete("\r").each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub(/^(snmp community) .*/, '\1 <hidden>')
  end

  cmd 'show system information' do |cfg|
    cfg.sub! /^Device Up Time.*\n/, ''
    cfg.delete! "\r"
    comment(cfg).gsub(/ +$/, '')
  end

  cmd 'show running-config' do |cfg|
    comment_next = 0
    cfg.each_line.map do |l|
      next '' if l =~ /^Building configuration/

      comment_next = 2 if l =~ /^Switch ID.*Hardware Version.*Firmware Version/

      if comment_next.positive?
        comment_next -= 1
        next comment(l)
      end

      l
    end.join.gsub(/ +$/, '')
  end
end
