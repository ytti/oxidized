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
    Root = File.join ENV['HOME'], '.config', 'oxidized'
  end

  CFGS = Asetus.new name: 'oxidized', load: false, key_to_s: true
  CFGS.default.syslogd.port        = 514
  CFGS.default.syslogd.file        = 'messages'
  CFGS.default.syslogd.resolve     = true

  begin
    CFGS.load
  rescue StandardError => error
    raise InvalidConfig, "Error loading config: #{error.message}"
  ensure
    CFG = CFGS.cfg # convenienence, instead of Config.cfg.password, CFG.password
  end

  class SyslogMonitor
    NAME_MAP = {
      /(.*)\.ip\.tdc\.net/ => '\1',
      /(.*)\.ip\.fi/       => '\1'
    }.freeze
    MSG = {
      ios:   /%SYS-(SW[0-9]+-)?5-CONFIG_I:/,
      junos: 'UI_COMMIT:',
      eos:   /%SYS-5-CONFIG_I:/,
      nxos:  /%VSHD-5-VSHD_SYSLOG_CONFIG_I:/
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

    def rest(opt)
      Oxidized::RestClient.next opt
    end

    def ios(ipaddr, log, index)
      # TODO: we need to fetch 'ip/name' in mode == :file here
      user = log[index + 5]
      from = log[-1][1..-2]
      rest(user: user, from: from, model: 'ios', ip: ipaddr,
           name: getname(ipaddr))
    end

    def jnpr(ipaddr, log, index)
      # TODO: we need to fetch 'ip/name' in mode == :file here
      user = log[index + 2][1..-2]
      msg  = log[(index + 6)..-1].join(' ')[10..-2]
      msg  = nil if msg == 'none'
      rest(user: user, msg: msg, model: 'jnpr', ip: ipaddr,
           name: getname(ipaddr))
    end

    def handle_log(log, ipaddr)
      log = log.to_s.split ' '
      if (i = log.find_index { |e| e.match(MSG[:ios]) })
        ios ipaddr, log,  i
      elsif (i = log.index(MSG[:junos]))
        jnpr ipaddr, log, i
      end
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
        NAME_MAP.each { |re, sub| name.sub! re, sub }
        name
      end
    end
  end
end

Oxidized::SyslogMonitor.udp
# Oxidized::SyslogMonitor.file '/var/log/poop'
