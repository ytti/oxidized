class TPLinkT1700X < Oxidized::Model
  using Refinements

  ###################################################
  #                Prompt & Comment Style           #
  ###################################################
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  comment '! '

  ###################################################
  #            Paging & Output Handling             #
  ###################################################
  expect /--More--|Press\s?any\s?key\s?to\s?continue\s?\(Q\s?to\s?quit\)/i do |data, re|
    send ' '
    data.sub re, ''
  end

  expect /[^>#\r\n]$/ do |data, re|
    send "\r"
    data.sub re, ''
  end

  cmd :secret do |cfg|
    cfg.gsub!(/^enable password (\S+)/, 'enable password <secret hidden>')
    cfg.gsub!(/^user (\S+) password (\S+) (.*)/, 'user \1 password <secret hidden> \3')
    cfg.gsub!(/^(snmp-server community).*/, '\1 <configuration removed>')
    cfg.gsub!(/secret (\d+) (\S+).*/, '<secret hidden>')
    cfg.gsub!(/(password|passwd|secret)(\s+)(\S+)/i, '\1\2<secret hidden>')
    cfg
  end

  ###################################################
  #         Secret Filtering (Passwords, etc.)      #
  ###################################################
  cmd :secret do |cfg|
    cfg.gsub!(/^enable password (\S+)/, 'enable password <secret hidden>')
    cfg.gsub!(/^user (\S+) password (\S+) (.*)/, 'user \1 password <secret hidden> \3')
    cfg.gsub!(/^(snmp-server community).*/, '\1 <configuration removed>')
    cfg.gsub!(/secret (\d+) (\S+).*/, '<secret hidden>')
    cfg.gsub!(/(password|passwd|secret)(\s+)(\S+)/i, '\1\2<secret hidden>')
    cfg
  end

  ###################################################
  #              System Information                 #
  ###################################################
  cmd 'show system-info' do |cfg|
    # Normalize line endings and split into lines
    lines = cfg.gsub(/\r\n?/, "\n").split("\n")
  
    # Remove any headers or unwanted lines at the start
    start_index = lines.find_index { |line| line.include?("System Description") }
    lines = lines[start_index..-1] if start_index
  
    # Identify where actual data ends before command prompt reappears
    end_index = lines.find_index { |line| line.match(/switch40\.bre\.bytemin\.net#/) }
    lines = lines[0...end_index] if end_index
  
    # Process each line to ensure it starts with a '! ' for correct formatting
    info = lines.map do |line|
      "! " + line.strip
    end.join("\n")
  
    # Construct the final output
    "\n\n! === System Information ===\n\n" + info + "\n"
  end

  ###################################################
  #           Core Device Configuration             #
  ###################################################
  cmd 'show backup-config' do |cfg|
    # Normalize line endings and split into lines
    lines = cfg.gsub(/\r\n?/, "\n").split("\n")
    
    # Optionally remove an unwanted header line at the start if there is one
    start_index = lines.find_index { |line| line.strip == "start of config" }  # Update this as per your device output
    lines = lines[(start_index + 1)..-1] if start_index
    
    # Identify the end of the configuration before any command prompts or unrelated output
    end_index = lines.find_index { |line| line.strip == "end" }
    lines = lines[0..end_index] if end_index  # Keep 'end' if it's part of the config format
    
    # Process each line to ensure it starts with a '! ' for correct formatting
    config = lines.map do |line|
      "! " + line.strip
    end.join("\n")
    
    # Construct the final output
    "\n\n! === Backup Config ===\n\n" + config + "\n"
  end


  ###################################################
  #              Connection Settings                #
  ###################################################
  cfg :telnet, :ssh do
    username /^User ?[nN]ame:/
    password /^\r?Password:/
  end

  ###################################################
  #           Login/Logout Sequences                #
  ###################################################
  cfg :telnet, :ssh do
    post_login do
      cmd "enable"
      send "\r"
    end

    pre_logout do
      send "exit\r"
      send "logout\r"
    end
  end
end
