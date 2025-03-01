class PowerConnect < Oxidized::Model
  using Refinements

  prompt /^([\w\s.@-]+(\(\S*\))?[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #

  comment '! '

  expect /\n\s*--More--\s+.*/ do |data, re| # Also grab the blank line above the --More--
    send ' '
    data.sub re, ''
  end

  # Filter all command output
  cmd :all do |cfg|
    cfg.gsub! /\r+/, ''                     # Remove the CR characters echoed back from the commands
    cfg.cut_tail                            # Drop the last line which is the next prompt
  end

  cmd :secret do |cfg|
    cfg.gsub! /^((?:enable |username \S+ )?password (?:level\s\d{1,2} |encrypted ){,2})\S+(.*)/, '\1<hidden>\2'
    cfg.gsub! /^(tacacs-server key) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    @stackable = true if @stackable.nil? && (cfg =~ /(U|u)nit\s/)
    cfg = cfg.split("\n").reject { |line| line[/Up\sTime/] }
    comment cfg.join("\n") + "\n"
  end

  cmd 'show system' do |cfg|
    @model = Regexp.last_match(1) if cfg =~ /Power[C|c]onnect (\d{4})[P|F]?/
    clean cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.sub(/^(sflow \S+ destination owner \S+ timeout )\d+$/, '! \1<timeout>') # Remove changing timeout
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

    post_login do
      cmd "terminal datadump"
      cmd "terminal length 0"
    end
    pre_logout do
      send "exit\r"
      sleep(0.25)
      send "logout\r"
    end
  end

  def clean(cfg)
    out = []
    len1 = len2 = skip_blocks = 0

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
      line = line.strip
      # If the temps were not removed by skipping blocks, then mask them out wih XXX
      # The most recent set of dashes has the spacing we want to match
      if (match = line.match(/^(---+ +)(---+ +)/))
        one, two = match.captures
        len1 = one.length
        len2 = two.length
      end
      # This can only be a temperature, right? ;-)
      if (match = line.match(/^(\d{1,2}) {3,}\d+ (.*)$/))
        one, two = match.captures
        line = one.to_s + (' ' * (len1 - one.length)) + "XXX" + (' ' * (len2 - 3)) + two.to_s
      end
      out << line
    end
    out = out.reject { |line| line[/Up\sTime/] } # Filter out Up Time
    out = comment out.join "\n"
    out << "\n"
  end
end
