module Oxidized
  module Models
    # # LinksysSRW model notes
    #
    # This is a switch model with a horible IE5 only web interface that is unusable in any modern browser due to broken and buggy html and javascript.
    #
    # On a first glance the serial or telnet interface isn't any more usable, but there is a way to break out of the menu driven interface and start a more usable cli.
    #
    # This is what this model does and dumps the config in there.
    #
    # As far as I know, the Linksys SRW 2008, SRW2016 , SRW2024 and SRW2048 are the only switches running this os/ui, but there might be others out there.
    #
    # Over snmp they identifes them self as Operating System: Cisco Small Business Software, so that might be a clue to look for if you're trying to figure out if your switch could have this hidden cli.
    #
    # The author of this model isn't the one who found this "hidden" cli but only someone who integrated it with oxidized. The real credits goes out to some unknown hero out there on the internet who figured this out a long time ago.
    #
    # Back to [Model-Notes](README.md)

    class LinksysSRW < Oxidized::Models::Model
      using Refinements

      comment '! '

      prompt /^([\r\w.@-]+[#>]\s?)$/

      # @!visibility private
      # Graphical login screen
      # Just login to get to Main Menu
      expect /Login Screen/ do
        Oxidized.logger.send(:debug, "#{self.class.name}: Login Screen")
        # @!visibility private
        # This is to ensure the whole thing have rendered before we send stuff
        sleep 0.2
        send 0x18.chr # CAN Cancel
        send @node.auth[:username]
        send "\t"
        send @node.auth[:password]
        send "\r"
        ''
      end

      # @!visibility private
      # Main menu, escape into Pre-cli-shell
      expect /Switch Main Menu/ do
        Oxidized.logger.send(:debug, "#{self.class.name}: Switch menu")
        send 0x1a.chr # SUB Substitite ^z
        ''
      end

      # @!visibility private
      # Pre-cli-shell, start lcli which is ios-ish
      expect />/ do
        Oxidized.logger.send(:debug, "#{self.class.name}: >")
        send "lcli\r"
        ''
      end

      cmd :all do |cfg|
        # @!visibility private
        # Remove \r from first response row
        cfg.gsub! /^\r/, ''
        cfg.cut_tail + "\n"
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
        cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
      end

      cmd 'show startup-config' do |cfg|
        # @!visibility private
        # Repair some linewraps which terminal datadump doesn't take care of
        # and there's no terminal width either.
        cfg.gsub! /(lldpPortConfigT)\n(LVsTxEnable)/, '\\1\\2'
        cfg.gsub! /(lldpPortConfigTL)\n(VsTxEnable)/, '\\1\\2'
        # @!visibility private
        # And comment out the echo of the command
        "#{comment cfg.lines.first}#{cfg.cut_head}"
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show system' do |cfg|
        cfg.gsub! /(System Up Time \(days,hour:min:sec\):\s+).*/, '\\1 <uptime removed>'
        comment cfg
      end

      cfg :telnet, :ssh do
        # @!visibility private
        # Some pre-cli-shell just expects a username, who its going to log in.
        username /^User Name:/
        password /Password:/
        post_login 'terminal datadump'
        pre_logout 'exit'
        pre_logout 'logout'
      end
    end
  end
end
