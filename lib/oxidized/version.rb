module Oxidized
  VERSION = '0.21.0'
  VERSION_FULL = '0.21.0-180-g9691008'
  def self.version_set
    Oxidized.send(:remove_const, :VERSION_FULL)
    const_set(:VERSION_FULL, %x(git describe --tags).chop)
    Oxidized.send(:remove_const, :VERSION)
    const_set(:VERSION, %x(git describe --tags --abbrev=0).chop)
    file = File.readlines(__FILE__)
    file[1] = "  VERSION = '%s'\n" % VERSION
    file[2] = "  VERSION_FULL = '%s'\n" % VERSION_FULL
    File.write(__FILE__, file.join)
  end
end
