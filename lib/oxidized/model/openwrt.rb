class OpenWrt < Oxidized::Model
  prompt /^[^#]+#/
  comment '#'

  cmd 'cat /etc/banner' do |cfg|
    comment "#### Info: /etc/banner #####\n#{cfg}"
  end

  cmd 'cat /proc/cpuinfo' do |cfg|
    comment "#### Info: /proc/cpuinfo #####\n#{cfg}"
  end

  cmd 'cat /etc/openwrt_release' do |cfg|
    comment "#### Info: /etc/openwrt_release #####\n#{cfg}"
  end

  cmd 'sysupgrade -l' do |cfg|
    @sysupgradefiles = cfg
    comment "#### Info: sysupgrade -l #####\n#{cfg}"
  end

  cmd 'cat /proc/mtd' do |cfg|
    @mtdpartitions = cfg
    comment "#### Info: /proc/mtd #####\n#{cfg}"
  end

  post do
    cfg = []
    binary_files = vars(:openwrt_binary_files) || %w[/etc/dropbear/dropbear_rsa_host_key]
    non_sensitive_files = vars(:openwrt_non_sensitive_files) || %w[rpcd uhttpd]
    partitions_to_backup = vars(:openwrt_partitions_to_backup) || %w[art devinfo u_env config caldata]
    @sysupgradefiles.lines.each do |sysupgradefile|
      sysupgradefile = sysupgradefile.strip
      if sysupgradefile.start_with?('/etc/config/')
        unless sysupgradefile.end_with?('-opkg')
          filename = sysupgradefile.split('/')[-1]
          cfg << comment("#### File: #{sysupgradefile} #####")
          uciexport = cmd("uci export #{filename}")
          Oxidized.logger.debug "Exporting uci config - #{filename}"
          if vars(:remove_secret) && !(non_sensitive_files.include? filename)
            Oxidized.logger.debug "Scrubbing uci config - #{filename}"
            uciexport.gsub!(/^(\s+option\s+(password|key)\s+')[^']+'/, '\\1<secret hidden>\'')
          end
          cfg << uciexport
        end
      elsif binary_files.include? sysupgradefile
        Oxidized.logger.debug "Exporting binary file - #{sysupgradefile}"
        cfg << comment("#### Binary file: #{sysupgradefile} #####")
        cfg << comment("Decode using 'echo -en <data> | gzip -dc > #{sysupgradefile}'")
        cfg << cmd("gzip -c #{sysupgradefile} | hexdump -ve '1/1 \"_x%.2x\"' | tr _ \\")
      elsif vars(:remove_secret) && sysupgradefile == '/etc/shadow'
        Oxidized.logger.debug 'Exporting and scrubbing /etc/shadow'
        cfg << comment("#### File: #{sysupgradefile} #####")
        shadow = cmd("cat #{sysupgradefile}")
        shadow.gsub!(/^([^:]+:)[^:]*(:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)/, '\\1\\2')
        cfg << shadow
      else
        Oxidized.logger.debug "Exporting file - #{sysupgradefile}"
        cfg << comment("#### File: #{sysupgradefile} #####")
        cfg << cmd("cat #{sysupgradefile}")
      end
    end
    @mtdpartitions.scan(/(\w+):\s+\w+\s+\w+\s+"(.*)"/).each do |partition, name|
      next unless vars(:openwrt_backup_partitions) && partitions_to_backup.include?(name)

      Oxidized.logger.debug "Exporting partition - #{name}(#{partition})"
      cfg << comment("#### Partition: #{name} /dev/#{partition} #####")
      cfg << comment("Decode using 'echo -en <data> | gzip -dc > #{name}'")
      cfg << cmd("dd if=/dev/#{partition} 2>/dev/null | gzip -c | hexdump -ve '1/1 \"%.2x\"'")
    end
    cfg.join "\n"
  end

  cfg :ssh do
    exec true
    pre_logout 'exit'
  end
end
