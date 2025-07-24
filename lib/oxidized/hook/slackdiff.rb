require 'slack_ruby_client'
require 'uri'
require 'net/http'

# defaults to posting a diff, if messageformat is supplied them a message will be posted too
# diff defaults to true

class SlackDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.token is required' unless cfg.has_key?('token')
    raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
  end

  def slack_upload(client, title, content, channel, proxy)
    logger.info "Posting diff as snippet to #{channel}"
    upload_dest = client.files_getUploadURLExternal(filename:     "change",
                                                    length:       content.length,
                                                    snippet_type: "diff")
    file_uri = URI.parse(upload_dest[:upload_url])

    proxy_uri = URI.parse(proxy) if proxy
    proxy_address = proxy_uri ? proxy_uri.host : :ENV
    proxy_port = proxy_uri&.port
    proxy_user = proxy_uri&.user
    proxy_pass = proxy_uri&.password

    http = Net::HTTP.new(file_uri.host, file_uri.port, proxy_address, proxy_port, proxy_user, proxy_pass)
    http.use_ssl = true

    request = Net::HTTP::Post.new(file_uri.request_uri, { Host: file_uri.host })
    request.body = content
    response = http.request(request)

    raise 'Slack file upload failed' unless response.is_a? Net::HTTPSuccess

    files = [{
      id:    upload_dest[:file_id],
      title: title
    }]
    begin
      client.files_completeUploadExternal(channel_id: channel,
                                          files:      files.to_json)
    rescue Slack::Web::Api::Errors::NotInChannel
      logger.info "Not in specified channel, attempting to join"
      client.conversations_join(channel: channel)
      client.files_completeUploadExternal(channel_id: channel,
                                          files:      files.to_json)
    end
  end

  def run_hook(ctx)
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    logger.info "Connecting to slack"
    Slack::Web::Client.configure do |config|
      config.token = cfg.token
      config.proxy = cfg.proxy if cfg.has_key?('proxy')
    end
    client = Slack::Web::Client.new
    client.auth_test
    logger.info "Connected"
    if cfg.has_key?("diff") ? cfg.diff : true
      gitoutput = ctx.node.output.new
      diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
      unless diff == "no diffs"
        title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
        content = diff[:patch].lines.to_a[4..-1].join
        slack_upload(client, title, content, cfg.channel, cfg.has_key?('proxy') ? cfg.proxy : nil)
      end
    end
    # message custom formatted - optional
    if cfg.message?
      logger.info cfg.message
      msg = cfg.message % { node: ctx.node.name.to_s, group: ctx.node.group.to_s, commitref: ctx.commitref,
                            model: ctx.node.model.class.name.to_s.downcase }
      logger.info msg
      logger.info "Posting message to #{cfg.channel}"
      client.chat_postMessage(channel: cfg.channel, text: msg, as_user: true)
    end
    logger.info "Finished"
  end
end
