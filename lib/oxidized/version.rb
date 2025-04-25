# frozen_string_literal: true

module Oxidized
  VERSION = '0.33.0'
  VERSION_FULL = '0.33.0'
  def self.version_set
    begin
      version_full = %x(git describe --tags).chop
      version      = %x(git describe --tags --abbrev=0).chop
    rescue StandardError
      version_full = ''
      version      = ''
    end

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
