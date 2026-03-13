class Riverbed < Oxidized::Model
  using Refinements

  # Define the prompt
  prompt /^.* *[\w-]+ *[#>] *$/

  # Define comment character
  comment '! '

  # Remove sensitive information
  cmd :secret do |cfg|
    cfg.gsub! /^( *tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( *username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( *ntp server .+ key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( *ntp peer .+ key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( *snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( *ip security shared secret).*/, '\\1 <secret hidden>'
    cfg.gsub! /^( *service shared-secret secret client).*/, '\\1 <secret hidden>'
    cfg.gsub! /^( *service shared-secret secret server).*/, '\\1 <secret hidden>'
    cfg
  end

  # Get version information and output it as comments
  cmd 'show version' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      output << comment("Product name: #{Regexp.last_match(1)}\n") if line =~ /^Product name:\s+(.*)$/
      output << comment("Product release: #{Regexp.last_match(1)}\n") if line =~ /^Product release:\s+(.*)$/
      output << comment("Build ID: #{Regexp.last_match(1)}\n") if line =~ /^Build ID:\s+(.*)$/
      output << comment("Build date: #{Regexp.last_match(1)}\n") if line =~ /^Build date:\s+(.*)$/
      output << comment("Build arch: #{Regexp.last_match(1)}\n") if line =~ /^Build arch:\s+(.*)$/
      output << comment("Built by: #{Regexp.last_match(1)}\n") if line =~ /^Built by:\s+(.*)$/
      output << comment("Product model: #{Regexp.last_match(1)}\n") if line =~ /^Product model:\s+(.*)$/
      output << comment("Number of CPUs: #{Regexp.last_match(1)}\n") if line =~ /^Number of CPUs:\s+(.*)$/
    end
    output + "\n"
  end

  # Get hardware information and output it as comments
  cmd 'show hardware all' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      output << comment("Hardware revision: #{Regexp.last_match(1)}\n") if line =~ /^Hardware revision:\s+(.*)$/
      output << comment("Mainboard: #{Regexp.last_match(1)}\n") if line =~ /^Mainboard:\s+(.*)$/
      if line =~ /^Slot (\d+):\s+\.*\s+(.*)$/
        slot_number = Regexp.last_match(1)
        slot_info = Regexp.last_match(2)
        output << comment("Slot #{slot_number}: #{slot_info}\n")
      end
      output << comment("System led: #{Regexp.last_match(1)}\n") if line =~ /^System led:\s+(.*)$/
    end
    output + "\n"
  end

  # Get serial information and output it as comment
  cmd 'show info' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      output << comment("Serial: #{Regexp.last_match(1)}\n") if line =~ /^Serial:\s+(.*)$/
    end
    output + "\n"
  end

  # Get the running configuration
  cmd 'show running-config' do |cfg|
    cfg = cfg.cut_both

    cfg = cfg.each_line.map do |line|
      if line =~ /^(.*##.*?##)(.*)$/
        comment_part = Regexp.last_match(1).strip
        command_part = Regexp.last_match(2).strip
        comment_line = comment(comment_part)
        if command_part.empty?
          comment_line + "\n"
        else
          comment_line + "\n" + command_part + "\n"
        end
      else
        line
      end
    end.join

    cfg
  end

  # SSH configuration
  cfg :ssh do
    post_login do
      cmd 'enable'
      cmd 'terminal length 0'
      cmd 'terminal width 1024'
    end
    pre_logout 'exit'
  end
end
