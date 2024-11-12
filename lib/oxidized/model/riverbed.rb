class Riverbed < Oxidized::Model
  using Refinements

  # Define the prompt
  PROMPT = /^.*\s*[\w-]+\s*[#>]\s*$/i
  prompt PROMPT

  # Define comment character
  comment '! '

  # Use procs to remove unwanted lines
  procs do
    # Remove "Last login" message
    proc { |output| output.gsub!(/^Last login:.*\n/, '') }
  end

  # Remove sensitive information
  cmd :secret do |cfg|
    cfg.gsub! /^(\s*tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*ntp server .+ key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*ntp peer .+ key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(\s*ip security shared secret).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*service shared-secret secret client).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s*service shared-secret secret server).*/, '\\1 <secret hidden>'
    cfg
  end

  # Get version information and store it
  cmd 'show version' do |cfg|
    # Remove the command echo and the hostname from the output
    cfg = cfg.cut_head
    cfg.gsub!(PROMPT, '')

    # Extract relevant information
    comments = []
    cfg.each_line do |line|
      line.strip!
      comments << "Product name: #{Regexp.last_match(1)}" if line =~ /^Product name:\s+(.*)$/
      comments << "Product release: #{Regexp.last_match(1)}" if line =~ /^Product release:\s+(.*)$/
      comments << "Build ID: #{Regexp.last_match(1)}" if line =~ /^Build ID:\s+(.*)$/
      comments << "Build date: #{Regexp.last_match(1)}" if line =~ /^Build date:\s+(.*)$/
      comments << "Build arch: #{Regexp.last_match(1)}" if line =~ /^Build arch:\s+(.*)$/
      comments << "Built by: #{Regexp.last_match(1)}" if line =~ /^Built by:\s+(.*)$/
      comments << "Product model: #{Regexp.last_match(1)}" if line =~ /^Product model:\s+(.*)$/
      comments << "Number of CPUs: #{Regexp.last_match(1)}" if line =~ /^Number of CPUs:\s+(.*)$/
    end
    @version_info = comments.join("\n")
    ''
  end

  # Get hardware information and store it
  cmd 'show hardware all' do |cfg|
    # Remove the command echo and the hostname from the output
    cfg = cfg.cut_head
    cfg.gsub!(PROMPT, '')

    # Extract relevant information
    comments = []
    cfg.each_line do |line|
      line.strip!
      comments << "Hardware revision: #{Regexp.last_match(1)}" if line =~ /^Hardware revision:\s+(.*)$/
      comments << "Mainboard: #{Regexp.last_match(1)}" if line =~ /^Mainboard:\s+(.*)$/
      if line =~ /^Slot (\d+):\s+\.*\s+(.*)$/
        slot_number = Regexp.last_match(1)
        slot_info = Regexp.last_match(2)
        comments << "Slot #{slot_number}: #{slot_info}"
      end
      comments << "System led: #{Regexp.last_match(1)}" if line =~ /^System led:\s+(.*)$/
    end
    @hardware_info = comments.join("\n")
    ''
  end

  # Get serial information from 'show info' command
  cmd 'show info' do |cfg|
    # Remove the command echo and the hostname from the output
    cfg = cfg.cut_head
    cfg.gsub!(PROMPT, '')

    # Extract the 'Serial:' line
    cfg.each_line do |line|
      line.strip!
      @serial_info = "Serial: #{Regexp.last_match(1)}" if line =~ /^Serial:\s+(.*)$/
    end
    ''
  end

  # Get the running configuration
  cmd 'show running-config' do |cfg|
    # Remove the first and last lines (command echo and hostname)
    cfg = cfg.cut_head.cut_tail

    # Process lines containing '##'
    cfg = cfg.each_line.map do |line|
      if line =~ /^(.*##.*?##)(.*)$/
        # Split the line into comment and rest
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

    # Prepend date, version, hardware, and serial information to the configuration
    header = []
    header << comment("Date of version: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}")
    header << comment(@serial_info) if @serial_info
    header << @version_info.each_line.map { |line| comment line }.join if @version_info
    header << @hardware_info.each_line.map { |line| comment line }.join if @hardware_info
    header.join("\n") + "\n" + cfg
  end

  # SSH configuration
  cfg :ssh do
    post_login do
      # Always enter enable mode
      cmd 'enable'
      cmd 'terminal length 0'
      cmd 'terminal width 1024'
    end
    pre_logout 'exit'
  end
end
