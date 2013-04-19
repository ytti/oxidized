module Oxidized
  class Config
    Root      = File.join ENV['HOME'], '.config', 'oxidized'
    Crash     = File.join Root, 'crash'
    InputDir  = File.join Directory, %w(lib oxidized input)
    OutputDir = File.join Directory, %w(lib oxidized output)
    ModelDir  = File.join Directory, %w(lib oxidized model)
    SourceDir = File.join Directory, %w(lib oxidized source) 
    Sleep     = 1
  end
  class << self
    attr_accessor :mgr
  end
end
