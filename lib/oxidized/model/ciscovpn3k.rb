module Oxidized
  module Models
    # Represents the CiscoVPN3k model.
    #
    # Handles configuration retrieval and processing for CiscoVPN3k devices.

    class CiscoVPN3k < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Used in Cisco VPN3000 concentrators
      # it have buggy code 227 reply with whitespace before trailing bracket
      # "227 Passive mode OK (172,16,0,9,4,9 )"
      # so use active ftp if you can. Or patch net/ftp

      cmd 'CONFIG'

      cfg :ftp do
      end
    end
  end
end
