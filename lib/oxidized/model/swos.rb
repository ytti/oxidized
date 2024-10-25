module Oxidized
  module Models
    # @!visibility private
    # Mikrotik SwOS (Lite)
    class SwOS < Oxidized::Models::Model
      using Refinements

      cmd '/backup.swb'
      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
        @secure = false
      end
    end
  end
end
