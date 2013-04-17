module Oxidized
  require 'logger'
  class Logger < Logger
    def initialize target=STDOUT
      super target
      self.level = Logger::DEBUG
    end
    def file= target
      @logdev = LogDevice.new target
    end
  end
  Log = Logger.new
end
