require 'fileutils'
require 'refinements'
require 'semantic_logger'

module Oxidized
  class OxidizedError < StandardError; end
  include SemanticLogger::Loggable

  Directory = File.expand_path(File.join(File.dirname(__FILE__), '../'))

  require 'oxidized/version'
  require 'oxidized/config'
  require 'oxidized/config/vars'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/hook'
  require 'oxidized/signals'
  require 'oxidized/core'
  require 'oxidized/logger'

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
