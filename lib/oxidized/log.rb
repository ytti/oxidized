module Oxidized

  begin
    require 'syslog/logger'
    Log = Syslog::Logger.new 'oxidized'
    Log.define_singleton_method(:file=){|arg|}
  rescue LoadError
    # 1.9.3 has no love for syslog
    require 'logger'
    class Logger < Logger
     def initialize target=STDOUT
       super target
     end
     def file= target
       @logdev = LogDevice.new target
     end
    end
    Log = Logger.new
  end

end
