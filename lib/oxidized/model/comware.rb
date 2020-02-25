class Comware < Oxidized::Model
  # HP (A-series)/H3C/3Com Comware

  # sometimes the prompt might have a leading nul or trailing ASCII Bell (^G)
  prompt /^\0*(<[\w.-]+>).?$/
  comment '# '

  # example how to handle pager
  # expect /^\s*---- More ----$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  cmd :all do |cfg|
    # cfg.gsub! /^.*\e\[42D/, ''        # example how to handle pager
    # skip rogue ^M
    cfg = cfg.delete "\r"
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^( snmp-agent community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( password hash).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( password cipher).*/, '\\1 <configuration removed>'
    cfg
  end

  cfg :telnet do
    username /^(Username|login):/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    # enable command-line mode on SMB comware switches (HP V1910, V1920)
    # autodetection is hard, because the 'summary' command is paged, and
    # the pager cannot be disabled before _cmdline-mode on.
    if vars :comware_cmdline
      post_login do
        # HP V1910, V1920
        cmd '_cmdline-mode on', /(#{@node.prompt}|Continue)/
        cmd 'y', /(#{@node.prompt}|input password)/
        cmd vars(:comware_cmdline)

        # HP V1950
        cmd 'xtd-cli-mode on', /(#{@node.prompt}|Continue)/
        cmd 'y', /(#{@node.prompt}|input password)/
        cmd vars(:comware_cmdline)
      end
    end

    post_login 'screen-length disable'
    post_login 'undo terminal monitor'
    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match /uptime/i }.join
    comment cfg
  end

  cmd 'display device' do |cfg|
    comment cfg
  end

  cmd 'display device manuinfo' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match 'FF'.hex.chr }.join
    comment cfg
  end

  cmd 'display current-configuration' do |cfg|
    cfg
  end
end
