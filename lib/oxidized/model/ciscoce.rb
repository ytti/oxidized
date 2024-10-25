module Oxidized
  module Models
    # @!visibility private
    # Supporting Cisco Catalyst Express Switches and IOS using the basic web interface
    class CiscoCE < Oxidized::Models::Model
      using Refinements

      cmd "/level/15/exec/-/show/startup-config" do |cfg|
        output = cfg.gsub(/\A.+<DL>(.+)<\/DL>.+\z/m, '\1') # Strip configuration file from within HTML response.
        output
      end

      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
      end
    end
  end
end
