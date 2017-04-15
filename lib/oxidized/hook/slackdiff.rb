require 'slack'

class SlackDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.token is required' unless cfg.has_key?('token')
    raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
  end

  def run_hook(ctx)
    if ctx.node
      if ctx.event.to_s == "post_store"
        log "Connecting to slack"
        Slack.configure do |config|
           config.token = cfg.token
           config.proxy = cfg.proxy if cfg.has_key?('proxy')
        end
        client = Slack::Client.new
        client.auth_test
        log "Connected"
        gitoutput = ctx.node.output.new
        diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
        title = "#{ctx.node.name.to_s} #{ctx.node.group.to_s} #{ctx.node.model.class.name.to_s.downcase}"
        log "Posting diff as snippet to #{cfg.channel}"
        client.files_upload(channels: cfg.channel, as_user: true,
                             content: diff[:patch].lines.to_a[4..-1].join,
                             filetype: "diff",
                             title: title,
                             filename: "change"
                            )
        log "Finished"
      end
    end
  end
end
