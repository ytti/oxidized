# frozen_string_literal: true

module Oxidized
  VERSION = '0.34.3'
  VERSION_FULL = '0.34.3'
  def self.version_set
    version_full = %x(git describe --tags).chop rescue ""
    version      = %x(git describe --tags --abbrev=0).chop rescue ""

    return false unless [version, version_full].none?(&:empty?)

    Oxidized.send(:remove_const, :VERSION)
    Oxidized.send(:remove_const, :VERSION_FULL)
    const_set(:VERSION, version)
    const_set(:VERSION_FULL, version_full)
    file = File.readlines(__FILE__)
    file[3] = "  VERSION = '%s'\n" % VERSION
    file[4] = "  VERSION_FULL = '%s'\n" % VERSION_FULL
    File.write(__FILE__, file.join)
  end
end
