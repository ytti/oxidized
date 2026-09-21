require 'json'
require 'zip'

class FTD < Oxidized::Model
  class FTDError < Oxidized::OxidizedError; end

  # Encapsulates the multi-step FTD configuration export workflow. Given the
  # http input, it drives the Secure Firewall Device Manager (FDM - Firepower
  # Device Manager) REST API: authenticate, schedule a config
  # export job, poll it, download the resulting zip and extract the config.
  class ConfigExporter
    include SemanticLogger::Loggable

    def initialize(http:, auth:, headers:, settings:)
      @http            = http
      @auth            = auth
      @headers         = headers
      @api_endpoint    = settings[:api_endpoint]
      @config_filename = settings[:config_filename]
      @polls           = settings[:polls]
      @poll_wait       = settings[:poll_wait]
    end

    def run
      login
      # Delete any pre-existing config file, otherwise the config export will fail.
      delete_config_file
      job_id = schedule_config_export
      job_status = poll_job_status(job_id)
      check_job_status(job_status)
      config_file = download_config_file
      delete_config_file
      extract_config(config_file)
    end

    private

    def login
      payload = {
        'grant_type' => 'password',
        'username'   => @auth[:username],
        'password'   => @auth[:password]
      }.to_json

      body = @http.post_http("#{@api_endpoint}/fdm/token", payload)
      token = JSON.parse(body)
      @headers['Authorization'] = "#{token['token_type']} #{token['access_token']}"
    rescue StandardError => e
      raise FTDError, "Login failed: #{e.message}"
    end

    def delete_config_file
      @http.delete_http("#{@api_endpoint}/action/configfiles/#{@config_filename}")
    rescue StandardError => e
      # Try to continue even if deletion fails.
      logger.debug "Deleting config file failed: #{e.message}"
    end

    def schedule_config_export
      payload = {
        'type'                => 'scheduleconfigexport',
        'diskFileName'        => @config_filename,
        'doNotEncrypt'        => true,
        'deployedObjectsOnly' => true
      }.to_json

      body = @http.post_http("#{@api_endpoint}/action/configexport", payload)
      config_export = JSON.parse(body)
      config_export['jobHistoryUuid']
    rescue StandardError => e
      raise FTDError, "Scheduling config export failed: #{e.message}"
    end

    def poll_job_status(job_id)
      job_status = nil

      @polls.times do
        sleep(@poll_wait)

        begin
          body = @http.get_http("#{@api_endpoint}/jobs/configexportstatus/#{job_id}")
          job_status = JSON.parse(body)
        rescue StandardError => e
          # Keep polling if a poll fails.
          logger.debug "Polling job status failed: #{e.message}"
        end

        break if %w[SUCCESS FAILED].include? job_status&.dig('status')
      end

      job_status
    end

    def check_job_status(job_status)
      status = job_status&.dig('status')
      return if status == 'SUCCESS'

      message = if status == 'FAILED'
                  job_status&.dig('statusMessage')
                else
                  job_status&.dig('error', 'messages', 0, 'description')
                end

      message ||= 'unknown error'
      raise FTDError, "Config export job failed: #{message}"
    end

    def download_config_file
      @http.get_http("#{@api_endpoint}/action/downloadconfigfile/#{@config_filename}")
    rescue StandardError => e
      raise FTDError, "Downloading config file failed: #{e.message}"
    end

    def extract_config(config_file)
      zipfile = Zip::File.open_buffer(config_file)
      config = zipfile.read('full_config.txt')
      JSON.parse(config)
    rescue Zip::Error => e
      raise FTDError, "Opening zip file failed: #{e.message}"
    rescue Errno::ENOENT
      raise FTDError, 'full_config.txt not found in zip file'
    rescue JSON::ParserError => e
      raise FTDError, "Parsing config JSON failed: #{e.message}"
    rescue StandardError => e
      raise FTDError, "Extracting config failed: #{e.message}"
    end
  end

  cfg_cb = lambda do
    FTD::ConfigExporter.new(
      # This callback is run via instance_exec on the http input, so `self` is
      # the HTTP input instance providing get_http/post_http/delete_http.
      http:     self,
      auth:     @node.auth,
      headers:  @headers,
      settings: {
        api_endpoint:    @api_endpoint,
        config_filename: @config_filename,
        polls:           @polls,
        poll_wait:       @poll_wait
      }
    ).run
  rescue FTDError => e
    logger.debug e.message
    false
  end

  cmd cfg_cb do |cfg|
    # generatedOn contains the timestamp of the config export. Delete it to avoid unnecessary differences.
    cfg[0].delete('generatedOn')

    # This needs to be 'distiniguishedNames', not 'distinguishedNames'.
    sort_list!(cfg, 'distinguishednamegroup', 'distiniguishedNames')
    sort_list!(cfg, 'geolocation', 'locations')

    JSON.pretty_generate(cfg)
  end

  cfg :http do
    @api_endpoint = vars(:ftd_api_endpoint) || '/api/fdm/latest'
    @config_filename = vars(:ftd_config_filename) || 'oxidized.zip'
    @polls = [vars(:ftd_polls)&.to_i || 10, 1].max
    @poll_wait = [vars(:ftd_poll_wait)&.to_i || 10, 1].max

    @secure = true
    @port = vars(:ftd_api_port) || 443

    @headers = {
      'Accept'       => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  private

  # Some lists seem to change order between exports. Sort the given list type
  # in-place by id to avoid unnecessary differences.
  def sort_list!(cfg, type, key)
    cfg.each_with_index.select { |element, _| element['type'] == 'identitywrapper' and element['data']['type'] == type }.map(&:last).each do |i|
      cfg[i]['data'][key].sort_by! { |element| element['id'] }
    end
  end
end
