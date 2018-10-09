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
    cfg = cfg.gsub /\r/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^( snmp-agent community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( password hash).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( password simple).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( super password level 3 simple).*/, '\\1 <configuration removed>'
    cfg
  end

  cfg :telnet do
    username /^Username:$/
    password /^Password:$/
  end

  cfg :telnet, :ssh do
    # enable command-line mode on SMB comware switches (HP V1910, V1920)
    # autodetection is hard, because the 'summary' command is paged, and
    # the pager cannot be disabled before _cmdline-mode on.
    if vars :comware_cmdline
      post_login do
        send "_cmdline-mode on\n"
        send "y\n"
        send vars(:comware_cmdline) + "\n"
        send "xtd-cli-mode on\n"
        send "y\n"
        send vars(:comware_cmdline) + "\n"
      end
    end

    if vars :comware_4200_cmdline
      # The 3Com 4200 (at least) series is different than other models:
      # other syntax to disable paging, and it has to be done within the
      # user interface.
      post_login do
        # enter system view
        send "system-view\n"
        # enter user interface
        send "user-interface vty 0\n"
        # disable paging
        send "screen-length 0\n"
        # leave user interface
        send "quit\n"
        # leave system view
        send "quit\n"
      end
    else
      # other models
      post_login 'screen-length disable'
      post_login 'undo terminal monitor'
    end

    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match /uptime/i }.join
    comment cfg
  end

  cmd 'display device' do |cfg|
    comment cfg
  end

  cmd 'display current-configuration' do |cfg|
    cfg
  end

  # somehow the 3Com 4200 needs a further call of a "display" action in
  # order to return the current configuration
  cmd 'display device'
end
