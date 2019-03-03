class PowerConnect < Oxidized::Model
  prompt /^([\w\s.@-]+(\(\S*\))?[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #

  comment '! '

  expect /^\s*--More--\s+.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(username \S+ password (?:encrypted )?)\S+(.*)/, '\1<hidden>\2'
    cfg.gsub! /^(tacacs-server key) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    if @stackable.nil?
      @stackable = true if cfg =~ /(U|u)nit\s/
    end
    cfg = cfg.split("\n").reject { |line| line[/Up\sTime/] }
    comment cfg.join("\n") + "\n"
  end

  cmd 'show system' do |cfg|
    @model = Regexp.last_match(1) if cfg =~ /Power[C|c]onnect (\d{4})[P|F]?/
    clean cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.sub(/^(sflow \S+ destination owner \S+ timeout )\d+$/, '! \1<timeout>')
  end

  cfg :telnet, :ssh do
    username /^User( Name)?:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /[pP]assword:/
        cmd vars(:enable)
      end
    end

    post_login "terminal datadump"
    post_login "terminal length 0"
    pre_logout "logout"
    pre_logout "exit"
  end

  def clean(cfg)
    out = []
    skip_blocks = 0
    cfg.each_line do |line|
      # If this is a stackable switch we should skip this block of information
      if line.match(/Up\sTime|Temperature|Power Suppl(ies|y)|Fans/i) && (@stackable == true)
        skip_blocks = 1
        # Some switches have another empty line. This is identified by this line having a colon
        skip_blocks = 2 if line =~ /:/
      end
      # If we have lines to skip do this until we reach and empty line
      if skip_blocks.positive?
        skip_blocks -= 1 if /\S/ !~ line
        next
      end
      out << line.strip
    end
    out = out.reject { |line| line[/Up\sTime/] }
    out = comment out.join "\n"
    out << "\n"
  end
end
