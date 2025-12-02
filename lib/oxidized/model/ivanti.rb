# frozen_string_literal: true

require 'json'

class Ivanti < Oxidized::Model
  prompt /$^/
  comment '! '

  BINARY_CONFIG_PATH = '/api/v1/system/binary-configuration'
  REALM_AUTH_PATH    = '/api/v1/realm_auth'
  DEFAULT_REALM      = 'Users'

  cmd BINARY_CONFIG_PATH do |b64|
    b64.to_s.lines.map(&:strip).join
  end

  cfg :http do
    @secure = true
    @port   = 443

    login_user = vars(:username) || @node.auth[:username]
    login_pass = vars(:password) || @node.auth[:password]
    realm      = vars(:realm)    || DEFAULT_REALM

    @username = login_user
    @password = login_pass

    payload = { realm: realm }.to_json

    response_body = post_http(
      REALM_AUTH_PATH,
      payload,
      'Content-Type'  => 'application/json',
      'Authorization' => basic_auth_header
    )

    begin
      login_data = JSON.parse(response_body)
    rescue JSON::ParserError => e
      Oxidized.logger.error(
        "Failed to parse realm_auth response: #{e.class}: #{e.message}, body=#{response_body.inspect}"
      )
      raise Oxidized::OxidizedError, 'Ivanti: realm_auth returned invalid JSON'
    end

    api_key = login_data['api_key']

    if api_key.nil? || api_key.empty?
      Oxidized.logger.error(
        "Failed to obtain api_key from realm_auth, response=#{response_body.inspect}"
      )
      raise Oxidized::OxidizedError, 'Ivanti: realm_auth did not return valid api_key'
    end

    @username = api_key
    @password = ''

    Oxidized.logger.debug "Obtained api_key #{api_key[0, 4]}... (len=#{api_key.length})"
  end
end
