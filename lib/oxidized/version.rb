module Oxidized
  VERSION = '0.22.0'
  VERSION_FULL = '0.22.0-10-ge8bee7b'
  def self.version_set
    version_full = %x(git describe --tags).chop rescue ""
    version      = %x(git describe --tags --abbrev=0).chop rescue ""

    return false unless [version, version_full].none?(&:empty?)

    Oxidized.send(:remove_const, :VERSION)
    Oxidized.send(:remove_const, :VERSION_FULL)
    const_set(:VERSION, version)
    const_set(:VERSION_FULL, version_full)
    file = File.readlines(__FILE__)
    file[1] = "  VERSION = '%s'\n" % VERSION
    file[2] = "  VERSION_FULL = '%s'\n" % VERSION_FULL
    File.write(__FILE__, file.join)
  end
end
