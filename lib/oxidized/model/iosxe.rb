module Oxidized
  module Models
    # @!visibility private
    # IOS parser should work here

    require_relative 'ios'

    # Represents the IOSXE model.
    #
    # Handles configuration retrieval and processing for IOSXE devices.
    IOSXE = IOS
  end
end
