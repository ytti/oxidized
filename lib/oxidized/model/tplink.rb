class TPLink < Oxidized::Model
  # tp-link prompt
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  comment '! '

  def ssh
    @input.class.to_s.match(/SSH/)
  end

  # With disable paging this is not needed
  # # handle paging
  # # workaround for sometimes missing whitespaces with "\s?"
  # expect /Press\s?any\s?key\s?to\s?continue\s?\(Q\s?to\s?quit\)/ do |data, re|
  #   send ' '
  #   data.sub re, ''
  # end

  # send carriage return because \n with the command is not enough
  # checks if line ends with prompt >,#,: or \r,\n otherwise send \r
  expect /[^>#\r\n:]$/ do |data, re|
    send "\r" if ssh
    data.sub re, ''
  end

  cmd :all do |cfg|
    # # remove unwanted paging line
    # cfg.gsub! /^Press any key to contin.*/, ''
    # normalize linefeeds
    cfg.gsub! /(\r|\r\n|\n\r)/, "\n"
    # remove empty lines
    cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^enable password (\S+)/, 'enable password <secret hidden>'
    cfg.gsub! /^user (\S+) password (\S+) (.*)/, 'user \1 password <secret hidden> \3'
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  cmd 'show system-info' do |cfg|
    cfg.gsub! /(System Time\s+-).*/, '\\1 <stripped>'
    cfg.gsub! /(Running Time\s+-).*/, '\\1 <stripped>'
    comment cfg.each_line.to_a[3..-3].join
  end

  cmd "show running-config" do |cfg|
    lines = cfg.each_line.to_a[1..-1]
    # cut config after "end"
    lines[0..lines.index("end\n")].join
  end

  cfg :telnet, :ssh do
    username /^(User ?[nN]ame|User):/
    password /^\r?[pP]assword:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        send vars(:enable) + "\n\r"
      end
      # disable paging
      cmd "terminal length 0"
      # enable-admin gives admin privileges for regular users
      # Sending enable-admin with an admin user returns a message warning that
      # the user already is admin without further consequences. So, always
      # send the enable-admin.
      # There is an option to set a password for enable-admin, but testing
      # with firmware 2.0.5 Build 20200109 Rel.36203 that option didn't works.
      # So we'll leave enable-admin without password here.
      cmd "enable-admin"
    end

    pre_logout do
      send "exit\r"
      send "logout\r"
    end
  end
end
