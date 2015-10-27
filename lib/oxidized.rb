module Oxidized
  class OxidizedError < StandardError; end
  Directory = File.expand_path File.join File.dirname(__FILE__), '../'
  require 'oxidized/core'

  def self.asetus
    @@asetus
  end

  def self.asetus=(val)
    @@asetus = val
  end

  def self.config
    asetus.cfg
  end
end
