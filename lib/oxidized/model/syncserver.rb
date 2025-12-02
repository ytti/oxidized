# Oxidized Model: Microchip SyncServer S650/S650i (firmware 5.2.x)
# API: GET /api/v1/admin/config + JSON body {"password": "Microchip"}
# Requires: HTTP Basic Auth, JSON body in GET (unusual), SSL bypass
# Returns: Encrypted XML config (~59KB)
#
# Node config: model=syncserver, username=admin, password=<admin_pass>
# Optional vars: syncserver_password=<encrypt_pass> (default: "Microchip")

require 'net/http'
require 'uri'
require 'openssl'

class Syncserver < Oxidized::Model
  comment '#'

  # Config fetch callback
  cfg_cb = lambda do
    Oxidized.logger.info "[+] syncserver model: starting config fetch for #{@node.ip}"

    # API request setup
    uri = URI("https://#{@node.ip}/api/v1/admin/config")
    req = Net::HTTP::Get.new(uri)
    req['Content-Type'] = 'application/json'
    req['User-Agent'] = 'Oxidized'
    req.basic_auth @node.auth[:username], @node.auth[:password]

    # JSON body in GET request (unusual but required by SyncServer)
    encrypt_password = (@node.vars && @node.vars[:syncserver_password]) || 'Microchip'
    req.body = "{\"password\": \"#{encrypt_password}\"}"

    # HTTPS with SSL bypass (self-signed certs)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.open_timeout = 30
    http.read_timeout = 60

    begin
      Oxidized.logger.debug "[+] syncserver model: making request to #{uri}"
      res = http.request(req)

      # Validate response
      raise "HTTP Error #{res.code}: #{res.message}" if res.code != '200'
      raise 'Empty config' if res.body.nil? || res.body.empty?

      Oxidized.logger.info "[+] syncserver model: successfully received #{res.body.length} bytes"

      # Return encrypted XML config
      res.body
    rescue StandardError => e
      Oxidized.logger.error "[!] syncserver model: error fetching config from #{@node.ip} - #{e.class}: #{e.message}"
      raise e
    end
  end

  # Register callback as command
  cmd cfg_cb

  # HTTP model config
  cfg :http do
    @secure = true
  end
end
