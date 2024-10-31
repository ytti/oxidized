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

  def slack_upload(client, title, content, channel)
    log "Posting diff as snippet to #{channel}"
    upload_dest = client.files_getUploadURLExternal(filename:     "change",
                                                    length:       content.length,
                                                    snippet_type: "diff")
    file_uri = URI.parse(upload_dest[:upload_url])

    http = Net::HTTP.new(file_uri.host, file_uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(file_uri.request_uri, { Host: file_uri.host })
    request.body = content
    response = http.request(request)

    raise 'Slack file upload failed' unless response.is_a? Net::HTTPSuccess

    files = [{
      id:    upload_dest[:file_id],
      title: title
    }]
    client.files_completeUploadExternal(channel_id: channel,
                                        files:      files.to_json)
  end

  def run_hook(ctx)
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    log "Connecting to slack"
    Slack::Web::Client.configure do |config|
      config.token = cfg.token
      config.proxy = cfg.proxy if cfg.has_key?('proxy')
    end
    client = Slack::Web::Client.new
    client.auth_test
    log "Connected"
    if cfg.has_key?("diff") ? cfg.diff : true
      gitoutput = ctx.node.output.new
      diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
      unless diff == "no diffs"
        title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
        content = diff[:patch].lines.to_a[4..-1].join
        slack_upload(client, title, content, cfg.channel)
      end
    end
    # message custom formatted - optional
    if cfg.message?
      log cfg.message
      msg = cfg.message % { node: ctx.node.name.to_s, group: ctx.node.group.to_s, commitref: ctx.commitref, model: ctx.node.model.class.name.to_s.downcase }
      log msg
      log "Posting message to #{cfg.channel}"
      client.chat_postMessage(channel: cfg.channel, text: msg, as_user: true)
    end
    log "Finished"
  end
end
