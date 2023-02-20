require 'net/http'
# Module for Audiocodes Mediant 90xx v7.4, using HTTP REST
class Audiocodes < Oxidized::Model
  # Configuring the module
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
  end
  # Get the INI configuration file
  cmd "/api/v1/files/ini"
end
