class PowerConnect < Oxidized::Model

  prompt /^([\w\s.@-]+[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #

  comment  '! '

  expect /^\s--More--\s+.*$/ do |data, re|
     send ' '
     data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    cfg = cfg.split("\n").select { |line| not line[/Up Time/] }
    cfg = cfg[0..-28]<<" "
    comment cfg.join("\n")
  end

  cmd 'show running-config'

  cfg :telnet do
    username /^User( Name)?:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end

    post_login "terminal length 0"
    pre_logout "logout"
    
  end

end
