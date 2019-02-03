class ASA < Oxidized::Model
  # Cisco ASA model #
  # Only SSH supported for the sake of security

  prompt /^\r*([\w.@()-\/]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /enable password (\S+) (.*)/, 'enable password <secret hidden> \2'
    cfg.gsub! /^passwd (\S+) (.*)/, 'passwd <secret hidden> \2'
    cfg.gsub! /username (\S+) password (\S+) (.*)/, 'username \1 password <secret hidden> \3'
    cfg.gsub! /(ikev[12] ((remote|local)-authentication )?pre-shared-key) (\S+)/, '\1 <secret hidden>'
    cfg.gsub! /^(aaa-server TACACS\+? \(\S+\) host[^\n]*\n(\s+[^\n]+\n)*\skey) \S+$/mi, '\1 <secret hidden>'
    cfg.gsub! /^(aaa-server \S+ \(\S+\) host[^\n]*\n(\s+[^\n]+\n)*\s+key) \S+$/mi, '\1 <secret hidden>'
    cfg.gsub! /ldap-login-password (\S+)/, 'ldap-login-password <secret hidden>'
    cfg.gsub! /^snmp-server host (.*) community (\S+)/, 'snmp-server host \1 community <secret hidden>'
    cfg.gsub! /^(failover key) .+/, '\1 <secret hidden>'
    cfg.gsub! /^(\s+ospf message-digest-key \d+ md5) .+/, '\1 <secret hidden>'
    cfg.gsub! /^(\s+ospf authentication-key) .+/, '\1 <secret hidden>'
    cfg.gsub! /^(\s+neighbor \S+ password) .+/, '\1 <secret hidden>'
    cfg
  end

  # check for multiple contexts
  cmd 'show mode' do |cfg|
    @is_multiple_context = cfg.include? 'multiple'
  end

  cmd 'show version' do |cfg|
    # avoid commits due to uptime / ixo-router01 up 2 mins 28 secs / ixo-router01 up 1 days 2 hours
    cfg = cfg.each_line.reject { |line| line.match /(\s+up\s+\d+\s+)|(.*days.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  post do
    if @is_multiple_context
      multiple_context
    else
      single_context
    end
  end

  cfg :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal pager 0'
    pre_logout 'exit'
  end

  def single_context
    # Single context mode
    cmd 'more system:running-config' do |cfg|
      cfg = cfg.each_line.to_a[3..-1].join
      cfg.gsub! /^: [^\n]*\n/, ''
      # backup any xml referenced in the configuration.
      anyconnect_profiles = cfg.scan(Regexp.new('(\sdisk0:/.+\.xml)')).flatten
      anyconnect_profiles.each do |profile|
        cfg << (comment profile + "\n")
        cmd("more" + profile) do |xml|
          cfg << (comment xml)
        end
      end
      # if DAP is enabled, also backup dap.xml
      if cfg.rindex(/dynamic-access-policy-record\s(?!DfltAccessPolicy)/)
        cfg << (comment "disk0:/dap.xml\n")
        cmd "more disk0:/dap.xml" do |xml|
          cfg << (comment xml)
        end
      end
      cfg
    end
  end

  def multiple_context
    # Multiple context mode
    cmd 'changeto system' do |cfg|
      cmd 'show running-config' do |systemcfg|
        allcfg = "\n\n" + systemcfg + "\n\n"
        contexts = systemcfg.scan(/^context (\S+)$/)
        files = systemcfg.scan(/config-url (\S+)$/)
        contexts.each_with_index do |cont, i|
          allcfg = allcfg + "\n\n----------========== [ CONTEXT " + cont.join(" ") + " FILE " + files[i].join(" ") + " ] ==========----------\n\n"
          cmd "more " + files[i].join(" ") do |cfgcontext|
            allcfg = allcfg + "\n\n" + cfgcontext
          end
        end
        cfg = allcfg
      end
      cfg
    end
  end
end
