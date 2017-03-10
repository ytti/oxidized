require 'slack'

# defaults to posting a diff, if messageformat is supplied them a message will be posted too
# diffenable defaults to true

class SlackDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.token is required' unless cfg.has_key?('token')
    raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
  end

  def run_hook(ctx)
    if ctx.node
      if ctx.event.to_s == "post_store"
        log "Connecting to slack"
        client = Slack::Client.new token: cfg.token
        client.auth_test
        log "Connected"
        # diff snippet - default
        diffenable = true
        if cfg.has_key?('diff') == true
          if cfg.diff == false
            diffenable = false
          end
        end
        if diffenable == true
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
        end
        # message custom formatted - optional
        if cfg.has_key?('message') == true
          log cfg.message
          msg = cfg.message % {:node => ctx.node.name.to_s, :group => ctx.node.group.to_s, :commitref => ctx.commitref, :model => ctx.node.model.class.name.to_s.downcase}
          log msg
          log "Posting message to #{cfg.channel}"
          client.chat_postMessage(channel: "#oxidized-test", text: msg,  as_user: true)
        end
        log "Finished"
      end
    end
  end
end
