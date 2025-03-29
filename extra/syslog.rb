#!/usr/bin/env ruby

# IOS:
# logging discriminator CFG mnemonics includes CONFIG_I
# logging host SERVER discriminator CFG

# JunOS:
# set system syslog host SERVER interactive-commands notice
# set system syslog host SERVER match "^mgd\[[0-9]+\]: UI_COMMIT: .*"

# Ports < 1024 need extra privileges, use a port higher than this by setting the port option in your oxidized config file.
# To use the default port for syslog (514) you shouldn't pass an argument, but you will need to allow this with:
# sudo setcap 'cap_net_bind_service=+ep' /usr/bin/ruby

# Config options are:
# syslogd
#  port (Default = 514)
#  file (Default = messages)
#  resolve (Default = true)

# To stop the resolution of IP's to PTR you can set resolve to false

# exit if fork   ## TODO: proper daemonize

require 'socket'
require 'resolv'
require_relative 'rest_client'

module Oxidized
  require 'asetus'
  class Config
    Root = File.join Dir.home, '.config', 'oxidized'
  end

  CFGS = Asetus.new name: 'oxidized', load: false, key_to_s: true
  CFGS.default.syslogd.port        = 514
  CFGS.default.syslogd.file        = 'messages'
  CFGS.default.syslogd.resolve     = true
  CFGS.default.syslogd.dns_map     = {
    '(.*)\.strip\.this\.domain\.com' => '\\1',
    '(.*)\.also\.this\.net'          => '\\1'
  }

  begin
    CFGS.load
  rescue StandardError => e
    raise InvalidConfig, "Error loading config: #{e.message}"
  ensure
    CFG = CFGS.cfg # convenienence, instead of Config.cfg.password, CFG.password
  end

  class SyslogMonitor
    MSG = {
      ios:   /%SYS-(?:SW[0-9]+-)?5-CONFIG_I:\s+Configured from console by (?<user>\w+) on [^\s]+ \((?<from>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\)/,
      junos: /UI_COMMIT: User '(?<user>\w+)' requested 'commit' operation \(comment: (?<msg>.+)\)/,
      eos:   /%SYS-5-CONFIG_I:\s+Configured from console by (?<user>\w+) on [^\s]+ \((?<from>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\)/,
      nxos:  /%VSHD-5-VSHD_SYSLOG_CONFIG_I: Configured from [^\s]+ by (?<user>\w+) on (?<from>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/,
      iosxr: /%MGBL-SYS-5-CONFIG_I : Configured from console by (?<user>\w+) on [^\s]+ \((?<from>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\)/,
      aruba: /Notice-Type='Running Config Change'.*User-Name='(?<user>\w+)'.*Remote-IP-Address='(?<from>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})'/
    }.freeze

    class << self
      def udp(port = Oxidized::CFG.syslogd.port, listen = 0)
        io = UDPSocket.new
        io.bind listen, port
        new io, :udp
      end

      def file(syslog_file = Oxidized::CFG.syslogd.file)
        io = File.open syslog_file, 'r'
        io.seek 0, IO::SEEK_END
        new io, :file
      end
    end

    private

    def initialize(io, mode = :udp)
      @mode = mode
      run io
    end

    def handle_log(log, ipaddr)
      vendor, match = nil, nil
      MSG.each do |key, value|
        vendor = key
        break if (match = value.match log)
      end
      return unless vendor && match

      # TODO: we need to fetch 'ip/name' in mode == :file here
      Oxidized::RestClient.next(
        {
          ip:    ipaddr,
          name:  getname(ipaddr),
          model: vendor.to_s,
          user:  match.named_captures.fetch("user", nil),
          from:  match.named_captures.fetch("from", nil),
          msg:   match.named_captures.fetch("msg", nil)
        }
      )
    end

    def run(io)
      loop do
        log = select [io]
        log, ip = log.first.first, nil
        if @mode == :udp
          log, ip = log.recvfrom_nonblock 2000
          ip = ip.last
        else
          begin
            log = log.read_nonblock 2000
          rescue EOFError
            sleep 1
            retry
          end
        end
        handle_log log, ip
      end
    end

    def getname(ipaddr)
      if Oxidized::CFG.syslogd.resolve == false
        ipaddr
      else
        name = (Resolv.getname ipaddr.to_s rescue ipaddr)
        Oxidized::CFG.syslogd.dns_map.each { |re, sub| name.sub! Regexp.new(re.to_s), sub }
        name
      end
    end
  end
end

Oxidized::SyslogMonitor.udp
# Oxidized::SyslogMonitor.file '/var/log/poop'
