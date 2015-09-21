class PowerConnect < Oxidized::Model

  prompt /^([\w\s.@-]+[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #

  comment  '! '

  expect /^\s*--More--\s+.*$/ do |data, re|
     send ' '
     data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show version' do |cfg|
    cfg = cfg.split("\n").select { |line| not line[/Up\sTime/] }
    comment cfg.join("\n") + "\n"
  end

  cmd 'show system' do |cfg|
    @model = $1 if cfg.match /Power[C|c]onnect (\d{4})[P|F]?/
    clean cfg
  end

  cmd 'show running-config'

  cfg :telnet, :ssh do
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

    post_login "terminal datadump"
    post_login "terminal length 0"
    pre_logout "logout"
    pre_logout "exit"
    
  end

  def clean cfg
    out = []
    skip_block = false
    cfg.each_line do |line|
      if line.match /Up\sTime|Temperature|Power Supplies/i
        # For 34xx, 35xx, 54xx, 55xx, 62xx and 8024F we should skip this block (terminated by a blank line)
        skip_block = true if @model =~ /^(34|35)(24|48)$|^(54|55)(24|48)$|^(62)(24|48)$|^8024$/
      end
      # If we have lines to skip do this until we reach and empty line
      if skip_block
        skip_block = false if /\S/ !~ line
        next
      end
      out << line.strip
    end
    out = comment out.join "\n"
    out << "\n"
  end

end
