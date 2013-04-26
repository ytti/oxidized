#!/usr/bin/env ruby

# IOS:
# logging discriminator CFG mnemonics includes CONFIG_I 
# logging host SERVER discriminator CFG

# JunOS:
# set system syslog host SERVER interactive-commands notice
# set system syslog host SERVER match "^mgd\[[0-9]+\]: UI_COMMIT: .*"

# sudo setcap 'cap_net_bind_service=+ep' /usr/bin/ruby

# exit if fork   ## TODO: proper daemonize

require 'socket'
require 'resolv'
require './rest_client'

module Oxidized
  class SyslogMonitor
    NAME_MAP = {
      /(.*)\.ip\.tdc\.net/ => '\1',
      /(.*)\.ip\.fi/       => '\1',
    }
    PORT = 514
    FILE = 'messages'
    MSG = {
      :ios   => '%SYS-5-CONFIG_I:',
      :junos => 'UI_COMMIT:',
    }

    class << self
      def udp port=PORT, listen=0
        io = UDPSocket.new
        io.bind listen, port
        new io, :udp
      end
      def file syslog_file=FILE
        io = open syslog_file, 'r'
        io.seek 0, IO::SEEK_END
        new io, :file
      end
    end

    private 

    def initialize io, mode=:udp
      @mode = mode
      run io
    end

    def rest opt
      Oxidized::RestClient.next opt
    end

    def ios ip, log, i
      # TODO: we need to fetch 'ip/name' in mode == :file here
      user = log[i+5]
      from = log[-1][1..-2]
      rest( :user => user, :from => from, :model => 'ios', :ip => ip,
            :name => getname(ip) )
    end

    def jnpr ip, log, i
      # TODO: we need to fetch 'ip/name' in mode == :file here
      user = log[i+2][1..-2]
      msg  = log[(i+6)..-1].join(' ')[10..-2]
      msg  = nil if msg == 'none'
      rest( :user => user, :msg => msg, :model => 'jnpr', :ip => ip,
            :name => getname(ip) )
    end

    def handle_log log, ip
      log = log.to_s.split ' '
      if i = log.index(MSG[:ios])
        ios ip, log,  i
      elsif i = log.index(MSG[:junos])
        jnpr ip, log, i
      end
    end

    def run io
      while true
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

    def getname ip
      name = (Resolv.getname ip.to_s rescue ip)
      NAME_MAP.each { |re, sub| name.sub! re, sub }
      name
    end
  end
end

Oxidized::SyslogMonitor.udp
#Oxidized::SyslogMonitor.file '/var/log/poop'
