# Developed against:
# #show version
# Switch ID       Hardware Version                Firmware Version
# 0               SSE-G48-TG4   (P2-01)           1.0.16-9
# and
# # show version
# Switch ID       Hardware Version                Firmware Version
# 0               MBM-XEM-002  (B6-01)            2.1.3-25

class AricentISS < Oxidized::Model
  using Refinements

  prompt /^(\e\[27m)?[ \r]*[\w-]+# ?$/

  cfg :ssh do
    # "pagination" was misspelled in some (earlier) versions (at least 1.0.16-9)
    # 1.0.18-15 is known to include the corrected spelling
    post_login 'no cli pagination'
    post_login 'no cli pagignation'
    # Starting firmware 2.0, pagination is done differently.
    # This configuration is reset after the session ends.
    post_login 'conf t; set cli pagination off; exit'
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
    comment(cfg).rstrip
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
    end.join.rstrip
  end
end
