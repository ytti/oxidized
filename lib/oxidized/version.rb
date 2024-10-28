module Oxidized
  # The current version of the Oxidized application.
  VERSION = '0.30.1'.freeze
  # The full version, including additional metadata if available.
  VERSION_FULL = '0.30.1'.freeze
  # Dynamically sets the application version by retrieving the latest Git tag and version.
  #
  # This method attempts to read the version and full version from Git tags, updates the constants,
  # and modifies the current file to store the new version and full version.
  #
  # @return [Boolean] returns `false` if no version information is found from Git tags.
  #
  # @raise [SystemCallError] if there is an issue reading or writing to the current file.
  def self.version_set
    # @!visibility private
    # Retrieve the full version and version from Git tags
    version_full = %x(git describe --tags).chop rescue ""
    version      = %x(git describe --tags --abbrev=0).chop rescue ""

    # @!visibility private
    # Return false if either the version or full version is empty
    return false unless [version, version_full].none?(&:empty?)

    # @!visibility private
    # Update the VERSION and VERSION_FULL constants
    Oxidized.send(:remove_const, :VERSION)
    Oxidized.send(:remove_const, :VERSION_FULL)
    const_set(:VERSION, version)
    const_set(:VERSION_FULL, version_full)
    # @!visibility private
    # Read the current file, update the version lines, and write the changes back
    file = File.readlines(__FILE__)
    file[1] = "  VERSION = '%s'.freeze\n" % VERSION
    file[2] = "  VERSION_FULL = '%s'.freeze\n" % VERSION_FULL
    File.write(__FILE__, file.join)
  end
end
