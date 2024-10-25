module Oxidized
  module Models
    # @!visibility private
    # For Zyxel OLTs series 1308
    class Zy1308 < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # For Zyxel OLTs series 1308

      cmd '/config_OLT-1308S-22.log'
      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
        @secure = false
      end
    end
  end
end
