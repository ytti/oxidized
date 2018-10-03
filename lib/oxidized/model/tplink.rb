class TPLink < Oxidized::Model
  # tp-link prompt
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  comment '! '

  # handle paging
  # workaround for sometimes missing whitespaces with "\s?"
  expect /Press\s?any\s?key\s?to\s?continue\s?\(Q\s?to\s?quit\)/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # send carriage return because \n with the command is not enough
  # checks if line ends with prompt >,# or \r,\nm otherwise send \r
  expect /[^>#\r\n]$/ do |data, re|
    send "\r"
    data.sub re, ''
  end

  cmd :all do |cfg|
    # remove unwanted paging line
    cfg.gsub! /Press any key to contine.*/, ''
    # normalize linefeeds
    cfg.gsub! /(\r|\r\n|\n\r)/, "\n"
    # remove empty lines
    cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  cmd 'show system-info' do |cfg|
    comment cfg.each_line.to_a[3..-3].join
  end

  cmd 'show running-config' do |cfg|
    lines = cfg.each_line.to_a[1..-1]
    # cut config after "end"
    lines[0..lines.index("end\n")].join
  end

  cfg :telnet, :ssh do
    username /^User ?[nN]ame:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\r"
        cmd vars(:enable)
      end
    end

    pre_logout do
      send "exit\r"
      send "logout\r"
    end
  end
end
