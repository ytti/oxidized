module Oxidized
  module Models
    # # Cumulus Linux
    #
    # ## Routing Daemon
    #
    # With the release of Cumulus Linux 3.4.0 the platform moved the routing daemon to a fork of `Quagga` named `FRRouting`. See the below link for the release notes.
    #
    # [https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes](https://support.cumulusnetworks.com/hc/en-us/articles/115011217808-Cumulus-Linux-3-4-0-Release-Notes)
    #
    # A variable has been added to enable users running Cumulus Linux > 3.4.0 to target the new `frr` routing daemon.
    #
    # ## NCLU
    # It is possible to switch to [NCLU](https://docs.nvidia.com/networking-ethernet-software/cumulus-linux-44/System-Configuration/Network-Command-Line-Utility-NCLU/) as a configuration collecting method, by setting `cumulus_use_nclu` to true
    #
    # ## NVUE
    # It is also possible to use [NVUE](https://docs.nvidia.com/networking-ethernet-software/knowledge-base/Setup-and-Getting-Started/NVUE-Cheat-Sheet/) as a configuration collecting method, by setting `cumulus_use_nvue` to true.
    #
    # ### Example usage
    #
    # ```yaml
    # vars:
    #   cumulus_routing_daemon: frr
    #   cumulus_use_nclu: true
    # ```
    #
    # Alternatively map a column for the  `cumulus_routing_daemon` variable.
    #
    # ```yaml
    # source:
    #   csv:
    #     map:
    #       name: 0
    #       ip: 1
    #       model: 2
    #       group: 3
    #     vars_map:
    #       cumulus_routing_daemon: 4
    # ```
    #
    # And set the `cumulus_routing_daemon` variable in the `router.db` file.
    #
    # ```text
    # cumulus1:192.168.121.134:cumulus:cumulus:frr
    # ```
    #
    # The default value for `cumulus_routing_daemon` is `quagga` so existing installations continue to operate without interruption.
    #
    # The default value for `cumulus_use_nclu` is `false`, in case NCLU is not installed.
    #
    # The default value for `cumulus_use_nvue` is `false`, in case NVUE is not installed.
    #
    # Back to [Model-Notes](README.md)

    # Represents the Cumulus model.
    #
    # Handles configuration retrieval and processing for Cumulus devices.

    class Cumulus < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(([\w.-]*)@(.*)):/
      comment '# '

      # @!visibility private
      # add a comment in the final conf
      def add_comment(comment)
        "\n###### #{comment} ######\n"
      end

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /password (\S+)/, 'password <hidden>'
        cfg
      end

      # @!visibility private
      # show the persistent configuration
      pre do
        use_nclu = vars(:cumulus_use_nclu) || false
        use_nvue = vars(:cumulus_use_nvue) || false

        if use_nclu
          cfg = cmd 'net show configuration commands'
        elsif use_nvue
          cfg = cmd 'nv config show --color off'
        else
          # @!visibility private
          # Set FRR or Quagga in config
          routing_daemon = vars(:cumulus_routing_daemon) ? vars(:cumulus_routing_daemon).downcase : 'quagga'
          routing_conf_file = routing_daemon == 'frr' ? 'frr.conf' : 'Quagga.conf'
          routing_daemon_shout = routing_daemon.upcase

          cfg = add_comment 'THE HOSTNAME'
          cfg += cmd 'cat /etc/hostname'

          cfg += add_comment 'THE HOSTS'
          cfg += cmd 'cat /etc/hosts'

          cfg += add_comment 'THE INTERFACES'
          cfg += cmd 'grep -r "" /etc/network/interface* | cut -d "/" -f 4-'

          cfg += add_comment 'RESOLV.CONF'
          cfg += cmd 'cat /etc/resolv.conf'

          cfg += add_comment 'NTP.CONF'
          cfg += cmd 'cat /etc/ntp.conf'

          cfg += add_comment 'SNMP settings'
          cfg += cmd 'cat /etc/snmp/snmpd.conf'

          cfg += add_comment "#{routing_daemon_shout} DAEMONS"
          cfg += cmd "cat /etc/#{routing_daemon}/daemons"

          cfg += add_comment "#{routing_daemon_shout} ZEBRA"
          cfg += cmd "cat /etc/#{routing_daemon}/zebra.conf"

          cfg += add_comment "#{routing_daemon_shout} BGP"
          cfg += cmd "cat /etc/#{routing_daemon}/bgpd.conf"

          cfg += add_comment "#{routing_daemon_shout} OSPF"
          cfg += cmd "cat /etc/#{routing_daemon}/ospfd.conf"

          cfg += add_comment "#{routing_daemon_shout} OSPF6"
          cfg += cmd "cat /etc/#{routing_daemon}/ospf6d.conf"

          cfg += add_comment "#{routing_daemon_shout} CONF"
          cfg += cmd "cat /etc/#{routing_daemon}/#{routing_conf_file}"

          cfg += add_comment 'MOTD'
          cfg += cmd 'cat /etc/motd'

          cfg += add_comment 'PASSWD'
          cfg += cmd 'cat /etc/passwd'

          cfg += add_comment 'SWITCHD'
          cfg += cmd 'cat /etc/cumulus/switchd.conf'

          cfg += add_comment 'PORTS'
          cfg += cmd 'cat /etc/cumulus/ports.conf'

          cfg += add_comment 'TRAFFIC'
          cfg += cmd 'cat /etc/cumulus/datapath/traffic.conf'

          cfg += add_comment 'ACL'
          cfg += cmd 'cat /etc/cumulus/acl/policy.conf'

          cfg += add_comment 'DHCP-RELAY'
          cfg += cmd 'cat /etc/default/isc-dhcp-relay'

          cfg += add_comment 'VERSION'
          cfg += cmd 'cat /etc/cumulus/etc.replace/os-release'

          cfg += add_comment 'License'
          cfg += cmd 'cl-license'
        end

        cfg
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login do
          if vars(:enable) == true
            cmd "sudo su -", /^\[sudo\] password/
            cmd @node.auth[:password]
          elsif vars(:enable)
            cmd "su -", /^Password:/
            cmd vars(:enable)
          end
        end

        pre_logout do
          cmd "exit" if vars(:enable)
        end
        pre_logout 'exit'
      end
    end
  end
end
