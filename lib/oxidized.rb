module Oxidized
  class OxidizedError < StandardError; end
  Encoding.default_external = 'UTF-8'
  Directory = File.expand_path File.join File.dirname(__FILE__), '../' 
  require 'oxidized/core'
end
