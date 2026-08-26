# frozen_string_literal: true

#
# Google Chat hook for Oxidized
#
# Supported events:
#   post_store - Sends a colorized configuration diff
#   node_fail  - Sends a plain-text configuration retrieval failure
#
# Optional LibreNMS integration:
#   Uses LibreNMS sysName as the friendly display name.
#   Falls back to the Oxidized node IP/name if lookup fails.
#

require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'thread'

class GoogleChat < Oxidized::Hook
  DEFAULT_MAX_DIFF_CHARS = 15_000
  DEFAULT_LIBRENMS_CACHE_TTL = 300
  DEFAULT_OPEN_TIMEOUT = 10
  DEFAULT_READ_TIMEOUT = 20

  def initialize
    super

    @librenms_cache = {}
    @librenms_cache_time = Time.at(0)
    @librenms_cache_mutex = Mutex.new

    @failure_alert_times = {}
    @failure_mutex = Mutex.new
  end

  # ----------------------------------------------------------
  # Validate hook configuration
  # ----------------------------------------------------------

  def validate_cfg!
    raise KeyError, 'hook.webhook_url is required' unless cfg.has_key?('webhook_url')

    webhook = cfg.webhook_url.to_s.strip
    raise ArgumentError, 'hook.webhook_url cannot be empty' if webhook.empty?

    uri = URI.parse(webhook)

    unless %w[http https].include?(uri.scheme) && uri.host
      raise ArgumentError, 'hook.webhook_url must be a valid HTTP/HTTPS URL'
    end

    if cfg.has_key?('librenms_api') ^ cfg.has_key?('librenms_token')
      raise ArgumentError,
            'hook.librenms_api and hook.librenms_token must either both be configured or both omitted'
    end

    if cfg.has_key?('max_diff_chars')
      value = cfg.max_diff_chars.to_i
      raise ArgumentError, 'hook.max_diff_chars must be greater than 0' unless value.positive?
    end

    if cfg.has_key?('librenms_cache_ttl')
      value = cfg.librenms_cache_ttl.to_i
      raise ArgumentError, 'hook.librenms_cache_ttl cannot be negative' if value.negative?
    end

    if cfg.has_key?('failure_cooldown')
      value = cfg.failure_cooldown.to_i
      raise ArgumentError, 'hook.failure_cooldown cannot be negative' if value.negative?
    end
  rescue URI::InvalidURIError
    raise ArgumentError, 'hook.webhook_url must be a valid HTTP/HTTPS URL'
  end

  # ----------------------------------------------------------
  # Main hook entrypoint
  # ----------------------------------------------------------

  def run_hook(ctx)
    unless ctx.node
      logger.warn '[GOOGLECHAT] Hook fired without a node; ignoring'
      return
    end

    case ctx.event.to_sym
    when :post_store
      handle_config_change(ctx)
    when :node_fail
      handle_node_failure(ctx)
    else
      logger.debug "[GOOGLECHAT] Ignoring unsupported event #{ctx.event}"
    end
  rescue StandardError => e
    logger.error "[GOOGLECHAT] Hook error for #{safe_node_identifier(ctx)}: #{e.class}: #{e.message}"
    logger.debug e.backtrace.join("\n") if e.backtrace
  end

  private

  # ==========================================================
  # CONFIG CHANGE
  # ==========================================================

  def handle_config_change(ctx)
    node = ctx.node

    ip = node_ip(node)
    display_name = lookup_display_name(node)

    logger.info(
      "[GOOGLECHAT] Configuration changed: " \
      "#{display_name} (#{ip}), commit=#{ctx.commitref}"
    )

    diff = get_diff(ctx)

    if diff.nil? || diff.empty?
      logger.warn(
        "[GOOGLECHAT] No usable diff returned for " \
        "#{display_name} (#{ip}); notification skipped"
      )
      return
    end

    diff = truncate_diff(diff)
    formatted_diff = format_diff(diff)

    payload = {
      cards: [
        {
          header: {
            title: 'Oxidized Config Change',
            subtitle: "#{display_name} (#{ip})",
            imageUrl: 'https://www.gstatic.com/images/icons/material/system/2x/settings_ethernet_black_48dp.png'
          },
          sections: [
            {
              widgets: [
                {
                  textParagraph: {
                    text: "<b>Timestamp:</b> #{CGI.escapeHTML(job_time(ctx))}"
                  }
                },
                {
                  textParagraph: {
                    text: "<b>Diff:</b><br>#{formatted_diff}"
                  }
                }
              ]
            }
          ]
        }
      ]
    }

    send_google_chat(payload)

    logger.info(
      "[GOOGLECHAT] Config change notification sent for " \
      "#{display_name} (#{ip})"
    )
  end

  # ----------------------------------------------------------
  # Obtain diff using Oxidized's output backend
  #
  # This follows the same basic approach as slackdiff.
  # ----------------------------------------------------------

  def get_diff(ctx)
    output = ctx.node.output.new

    unless output.respond_to?(:get_diff)
      logger.error(
        "[GOOGLECHAT] Output backend #{output.class} does not support get_diff"
      )
      return nil
    end

    result = output.get_diff(
      ctx.node,
      ctx.node.group,
      ctx.commitref,
      nil
    )

    return nil if result.nil?
    return nil if result == 'no diffs'

    patch =
      if result.respond_to?(:[])
        result[:patch] || result['patch']
      end

    return nil unless patch

    lines = patch.lines.to_a

    # Oxidized's slackdiff strips the first four patch header lines.
    # Do the same when they exist.
    if lines.length > 4
      body = lines[4..].join
      return body unless body.empty?
    end

    patch
  rescue StandardError => e
    logger.error(
      "[GOOGLECHAT] Unable to generate diff for " \
      "#{safe_node_identifier(ctx)}: #{e.class}: #{e.message}"
    )
    nil
  end

  # ----------------------------------------------------------
  # Truncate large diffs
  # ----------------------------------------------------------

  def truncate_diff(diff)
    max_chars =
      if cfg.has_key?('max_diff_chars')
        cfg.max_diff_chars.to_i
      else
        DEFAULT_MAX_DIFF_CHARS
      end

    return diff if diff.length <= max_chars

    logger.warn(
      "[GOOGLECHAT] Diff is #{diff.length} characters; " \
      "truncating to #{max_chars}"
    )

    "#{diff[0, max_chars]}\n\n[truncated...]"
  end

  # ----------------------------------------------------------
  # Google Chat HTML diff formatting
  # ----------------------------------------------------------

  def format_diff(diff)
    diff.each_line.map do |line|
      escaped = CGI.escapeHTML(line.chomp)

      if line.start_with?('+')
        %(<font color="#00C853">#{escaped}</font><br>)
      elsif line.start_with?('-')
        %(<font color="#D50000">#{escaped}</font><br>)
      else
        %(<font color="#9E9E9E">#{escaped}</font><br>)
      end
    end.join
  end

  # ==========================================================
  # NODE FAILURE
  # ==========================================================

  def handle_node_failure(ctx)
    node = ctx.node

    ip = node_ip(node)
    display_name = lookup_display_name(node)

    if failure_suppressed?(node)
      logger.info(
        "[GOOGLECHAT] Failure notification suppressed by cooldown for " \
        "#{display_name} (#{ip})"
      )
      return
    end

    error_reason = failure_reason(node, ctx)
    error_type = failure_type(node)

    logger.warn(
      "[GOOGLECHAT] Config retrieval failed for " \
      "#{display_name} (#{ip}): #{error_reason}"
    )

    #
    # Deliberately plain text.
    #
    # This produces cleaner Google Chat notifications and is
    # considerably better for Android Auto/read-aloud behavior.
    #
    text = "Config check failed on #{display_name} (#{ip}). #{error_reason}"

    # Add type only when useful and when it isn't already effectively
    # duplicated by the reason.
    if show_error_type? && !error_type.empty?
      text += " [#{error_type}]"
    end

    payload = {
      text: text
    }

    send_google_chat(payload)
    record_failure_alert(node)

    logger.info(
      "[GOOGLECHAT] Failure notification sent for " \
      "#{display_name} (#{ip})"
    )
  end

  # ----------------------------------------------------------
  # Failure details
  # ----------------------------------------------------------

  def failure_reason(node, ctx)
    values = []

    values << node.err_reason.to_s if node.respond_to?(:err_reason)
    values << node.msg.to_s if node.respond_to?(:msg)

    if ctx.job && ctx.job.respond_to?(:status)
      values << ctx.job.status.to_s
    end

    reason = values.find { |value| !value.nil? && !value.strip.empty? }

    reason || 'Unknown error'
  end

  def failure_type(node)
    return '' unless node.respond_to?(:err_type)

    node.err_type.to_s.strip
  end

  def show_error_type?
    return false unless cfg.has_key?('show_error_type')

    !!cfg.show_error_type
  end

  # ==========================================================
  # FAILURE DEDUPLICATION / COOLDOWN
  # ==========================================================

  def failure_cooldown
    return 0 unless cfg.has_key?('failure_cooldown')

    cfg.failure_cooldown.to_i
  end

  def failure_suppressed?(node)
    cooldown = failure_cooldown
    return false unless cooldown.positive?

    key = node_cache_key(node)

    @failure_mutex.synchronize do
      previous = @failure_alert_times[key]
      next false unless previous

      (Time.now - previous) < cooldown
    end
  end

  def record_failure_alert(node)
    return unless failure_cooldown.positive?

    key = node_cache_key(node)

    @failure_mutex.synchronize do
      @failure_alert_times[key] = Time.now
    end
  end

  # ==========================================================
  # LIBRENMS NAME LOOKUP
  # ==========================================================

  def lookup_display_name(node)
    fallback = node_ip(node)

    unless librenms_configured?
      logger.debug(
        "[GOOGLECHAT] LibreNMS lookup not configured; using #{fallback}"
      )
      return fallback
    end

    devices = librenms_devices

    unless devices
      logger.warn(
        "[GOOGLECHAT] LibreNMS device lookup unavailable; using #{fallback}"
      )
      return fallback
    end

    node_name = node.name.to_s
    ip = node.ip.to_s

    device = devices.find do |entry|
      next false unless entry.is_a?(Hash)

      candidates = [
        entry['ip'],
        entry['hostname'],
        entry['sysName']
      ].compact.map(&:to_s)

      candidates.include?(ip) || candidates.include?(node_name)
    end

    unless device
      logger.warn(
        "[GOOGLECHAT] Device #{ip} was not found in LibreNMS; using IP"
      )
      return fallback
    end

    sysname = device['sysName'].to_s.strip

    if sysname.empty?
      logger.warn(
        "[GOOGLECHAT] LibreNMS has no sysName for #{ip}; using IP"
      )
      return fallback
    end

    logger.debug(
      "[GOOGLECHAT] LibreNMS name resolved: #{ip} -> #{sysname}"
    )

    sysname
  rescue StandardError => e
    logger.warn(
      "[GOOGLECHAT] LibreNMS name lookup failed for #{fallback}: " \
      "#{e.class}: #{e.message}; using IP"
    )

    fallback
  end

  def librenms_configured?
    cfg.has_key?('librenms_api') &&
      cfg.has_key?('librenms_token') &&
      !cfg.librenms_api.to_s.strip.empty? &&
      !cfg.librenms_token.to_s.strip.empty?
  end

  # ----------------------------------------------------------
  # Cache entire LibreNMS device listing.
  #
  # This avoids making one API request for every Oxidized
  # post_store/node_fail event.
  # ----------------------------------------------------------

  def librenms_devices
    ttl =
      if cfg.has_key?('librenms_cache_ttl')
        cfg.librenms_cache_ttl.to_i
      else
        DEFAULT_LIBRENMS_CACHE_TTL
      end

    @librenms_cache_mutex.synchronize do
      cache_valid =
        !@librenms_cache.empty? &&
        ttl.positive? &&
        (Time.now - @librenms_cache_time) < ttl

      return @librenms_cache if cache_valid

      devices = fetch_librenms_devices

      if devices
        @librenms_cache = devices
        @librenms_cache_time = Time.now
      elsif !@librenms_cache.empty?
        # If LibreNMS has a temporary outage, use the previous cached
        # device list rather than throwing away a previously valid map.
        logger.warn(
          '[GOOGLECHAT] LibreNMS refresh failed; using stale name cache'
        )
      end

      @librenms_cache.empty? ? nil : @librenms_cache
    end
  end

  def fetch_librenms_devices
    uri = URI.parse(cfg.librenms_api.to_s)

    request = Net::HTTP::Get.new(uri.request_uri)
    request['X-Auth-Token'] = cfg.librenms_token.to_s
    request['Accept'] = 'application/json'

    response = http_request(uri, request)

    unless response.is_a?(Net::HTTPSuccess)
      logger.warn(
        "[GOOGLECHAT] LibreNMS API returned HTTP #{response.code}"
      )
      return nil
    end

    body = JSON.parse(response.body)

    devices =
      if body.is_a?(Hash)
        body['devices']
      elsif body.is_a?(Array)
        body
      end

    unless devices.is_a?(Array)
      logger.warn(
        '[GOOGLECHAT] LibreNMS API response did not contain a device array'
      )
      return nil
    end

    logger.debug(
      "[GOOGLECHAT] Cached #{devices.length} LibreNMS devices"
    )

    devices
  rescue JSON::ParserError => e
    logger.warn(
      "[GOOGLECHAT] LibreNMS returned invalid JSON: #{e.message}"
    )
    nil
  rescue URI::InvalidURIError => e
    logger.warn(
      "[GOOGLECHAT] Invalid LibreNMS API URL: #{e.message}"
    )
    nil
  rescue StandardError => e
    logger.warn(
      "[GOOGLECHAT] LibreNMS API request failed: #{e.class}: #{e.message}"
    )
    nil
  end

  # ==========================================================
  # GOOGLE CHAT HTTP
  # ==========================================================

  def send_google_chat(payload)
    uri = URI.parse(cfg.webhook_url.to_s)

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json; charset=UTF-8'
    request['Accept'] = 'application/json'
    request.body = JSON.generate(payload)

    response = http_request(uri, request)

    unless response.is_a?(Net::HTTPSuccess)
      raise(
        "Google Chat webhook returned HTTP #{response.code}: " \
        "#{safe_response_body(response.body)}"
      )
    end

    response
  end

  # ----------------------------------------------------------
  # Shared HTTP client
  # ----------------------------------------------------------

  def http_request(uri, request)
    proxy_uri =
      if cfg.has_key?('proxy') && !cfg.proxy.to_s.strip.empty?
        URI.parse(cfg.proxy.to_s)
      end

    http =
      if proxy_uri
        Net::HTTP::Proxy(
          proxy_uri.host,
          proxy_uri.port,
          proxy_uri.user,
          proxy_uri.password
        ).new(uri.host, uri.port)
      else
        Net::HTTP.new(uri.host, uri.port)
      end

    http.use_ssl = uri.scheme == 'https'

    http.open_timeout =
      cfg.has_key?('open_timeout') \
        ? cfg.open_timeout.to_i \
        : DEFAULT_OPEN_TIMEOUT

    http.read_timeout =
      cfg.has_key?('read_timeout') \
        ? cfg.read_timeout.to_i \
        : DEFAULT_READ_TIMEOUT

    http.request(request)
  end

  # ==========================================================
  # GENERAL HELPERS
  # ==========================================================

  def node_ip(node)
    ip = node.ip.to_s.strip if node.respond_to?(:ip)
    return ip unless ip.nil? || ip.empty?

    name = node.name.to_s.strip if node.respond_to?(:name)
    return name unless name.nil? || name.empty?

    'Unknown'
  end

  def node_cache_key(node)
    "#{node.group}/#{node.name}"
  end

  def safe_node_identifier(ctx)
    return 'unknown node' unless ctx && ctx.node

    "#{ctx.node.group}/#{ctx.node.name}"
  end

  def job_time(ctx)
    return Time.now.to_s unless ctx.job
    return ctx.job.time.to_s if ctx.job.respond_to?(:time)

    Time.now.to_s
  end

  def safe_response_body(body)
    text = body.to_s.gsub(/\s+/, ' ').strip
    return '(empty response)' if text.empty?

    text[0, 500]
  end
end
