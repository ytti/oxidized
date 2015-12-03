module Oxidized
  require 'logger'

  class Logger < Logger
    def initialize target=STDOUT
      super target
    end
    def file= target
      FileUtils.mkdir_p File.dirname(target)
      @logdev = LogDevice.new target
    end
  end

  Log = Logger.new
end
