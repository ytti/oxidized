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

  cmd 'display current-configuration' do |cfg|
    cfg
  end

  def parse output
    info = {}

    output.match(/# (3Com Corporation)/) do
      info[:manufacturer] = Regexp.last_match(1)
    end

    output.match(/# (Switch .+?) Software Version 3Com OS (V[0-9.a-z]+)/) do
      info[:name] = Regexp.last_match(1)
      info[:version] = Regexp.last_match(2)
    end

    output.match(/Switch .+? 48-Port with ([0-9]+) Processor/) do
      info[:cores] = Regexp.last_match(1).to_i
    end

    output.match(/# ([0-9]+)M   bytes DRAM/) do
      info[:ram] = Regexp.last_match(1).to_i * 1024 * 1024
    end

    output.match(/# ([0-9]+)M   bytes Flash Memory/) do
      info[:hdd] = Regexp.last_match(1).to_i * 1024 * 1024
    end

    info
  end
end
