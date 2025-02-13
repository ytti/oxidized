class StarOS < Oxidized::Model
    prompt /^(\[[A-Za-z0-9_-]+\][A-Za-z0-9_-]+[#>]\s+$)/
    comment  '# '
  
    cmd :all do |cfg|
      # get rid of errors for commands that don't work on some devices
      cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
      cfg.cut_both
    end
  
    cmd :secret do |cfg|
      cfg.gsub! /^(\s+license key) "(.*?)"$/m, '\1 <secret hidden>'
      cfg.gsub! /\s+(?:password|encrypted-url.|encrypted-secondary-url.|encrypted name|security-name|encrypted key) (?:\S)?\S+/, '\\1 <secret hidden>'
      cfg.gsub! /^(\s+ssh key) (.*?) type v2-rsa$/m, '\1 <secret hidden>'
      cfg.gsub! /^(\s+ssl-certificate string) "(.*?)"$/m, '\1 <secret hidden>'
      cfg.gsub! /^(\s+ssl-private-key string) "(.*?)"$/m, '\1 <secret hidden>'
      cfg
    end
  
    # current software version and image filename
    cmd 'show version' do |cfg|
      comments = []
      comments << "Active Software:\n"
      lines = cfg.lines
      lines.each_with_index do |line, i|
        comments << "StarOS Version: #{Regexp.last_match(1)}" if line =~ /Image Version: \S* (.*)$/
        comments << "Boot Image: #{Regexp.last_match(1)}" if line =~ /Boot Image: \S* (.*)$/
      end
      comments << "\n"
      comment comments.join "\n"
    end
  
    # diameter peers and status
    cmd 'show diameter peers full | grep -E "Hostname|State|Peers"' do |state|
      comments = []
      comments << "\nDiameter Peers:\n"
      comments << state
      comments << "\n"
      comment comments.join "\n"
    end
  
    # service status and max sessions
    cmd 'show service all' do |state|
      comments = []
      comments << "\nServices configured:\n"
      comments << state
      comments << "\n"
      comment comments.join "\n"
    end
  
    # PGW service newcall policy and PLMN served
    cmd 'show pgw-service all' do |state|
      comments = []
      comments << "\nPGW services\n"
      lines = state.lines
      lines.each_with_index do |line, i|
        comments << "Service: #{Regexp.last_match(1)}" if line =~ /Service name                  : (.*)$/
        comments << "PLMN ID: #{Regexp.last_match(1)}" if line =~ /PLMN ID List                  : (.*)$/
        comments << "Newcall: #{Regexp.last_match(1)}" if line =~ /Newcall Policy                : (.*)$/
      end
      comments << "\n"
      comment comments.join "\n"
    end
  
  
    # GGSN service newcall policy and PLMN served
    cmd 'show ggsn-service all' do |state|
      comments = []
      comments << "\nGGSN services\n"
      lines = state.lines
      lines.each_with_index do |line, i|
        comments << "Service: #{Regexp.last_match(1)}" if line =~ /Service name:           (.*)$/
        comments << "PLMN ID: #{Regexp.last_match(1)}" if line =~ /Self PLMN Id.:          (.*)$/
        comments << "Newcall: #{Regexp.last_match(1)}" if line =~ /Newcall Policy:         (.*)$/
      end
      comments << "\n"
      comment comments.join "\n"
    end
  
    # APN newcall policy
    cmd 'show apn all | grep -E "access point name|Newcall"' do |state|
      comments = []
      comments << "\nAPN policy:\n"
      comments << state
      comments << "\n"   
      comment comments.join "\n"
    end
  
    
    cmd 'show context' do |context|
      Oxidized.logger.debug "Getting list of contexts..."
      interfaces = context + "\n\n"
      contexts = context.scan(/^(\S+)\s+\d/)
      Oxidized.logger.debug "#{contexts}"
      contexts.each_with_index do |cont, i|
        Oxidized.logger.debug "Showing interfaces for context - #{cont} (index #{i})"
        cmd "context " + cont.join(" ") do |changecontext|
          interfaces = interfaces + "\n\n----------========== [ CONTEXT " + cont.join(" ") + " ] ==========----------\n\n"
          # IP interfaces (physical and loopback)
          cmd 'show ip interface summary' do |state|
            state.gsub! /^Total interface count.*\n/, ''
            interfaces = interfaces + "\nIP interfaces:\n" + state
          end

          # IP routes
          cmd 'show ip route' do |state|
            state.gsub! /^"\*" indicates the Best or Used route.  S indicates Stale.\n/, ''
            interfaces = interfaces + "\nIP routes:\n" + state
          end
        end
      end
      comment interfaces
    end

    # boot priority list
    cmd 'show boot' do |cfg|
      comment "\n------------------------------ Configuration: ------------------------------\n"
      cfg
    end
  
    # config section
    cmd 'show config' do |cfg|
      cfg
    end
  
    cfg :ssh do
      # preferred way to handle additional passwords
      post_login do
        # test-commands is staros debug mode which opens up more commands
        # must configure cli-hidden and test-cmd password, must be admin role
        # NOT RECOMMENDED FOR PRODUCTION UNLESS OTHERWISE REQUIRED FOR CISCO TAC
        if vars(:enable)
          cmd "cli test-commands password " + vars(:enable)
        end
      end
      # disable timestamps and set screen width to max, disable paging with len 0
      post_login 'no timestamps'
      post_login 'terminal length 0'
      post_login 'terminal width 512'
      pre_logout 'exit'
    end
end
