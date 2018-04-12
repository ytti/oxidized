require 'cisco_spark'

# defaults to posting a diff, if messageformat is supplied them a message will be posted too
# diffenable defaults to true
# Modified from slackdiff

class CiscoSparkDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.accesskey is required' unless cfg.has_key?('accesskey')
    raise KeyError, 'hook.space is required' unless cfg.has_key?('space')
  end

  def run_hook(ctx)
    if ctx.node
      if ctx.event.to_s == "post_store"
        log "Connecting to Cisco Spark"
        CiscoSpark.configure do |config|
           config.api_key = cfg.accesskey
           config.proxy = cfg.proxy if cfg.has_key?('proxy')
        end
         space = cfg.space
         client = CiscoSpark::Room.new(id: space)
         client.fetch
         log "Connected"
        diffenable = true
        if cfg.has_key?('diff') == true
          if cfg.diff == false
            diffenable = false
          end
        end
        if diffenable == true
          gitoutput = ctx.node.output.new
          diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
          title = "#{ctx.node.name.to_s}"
          log "Posting diff as snippet to #{cfg.space}"
          message = CiscoSpark::Message.new(text: 'Device ' + title + ' modified:' + "\n" + diff[:patch].lines.to_a[4..-1].join)
          room = CiscoSpark::Room.new(id: space)
          room.send_message(message)
        end
        if cfg.has_key?('message') == true
          log cfg.message
          msg = cfg.message % {:node => ctx.node.name.to_s, :group => ctx.node.group.to_s, :commitref => ctx.commitref, :model => ctx.node.model.class.name.to_s.downcase}
          log msg
          log "Posting message to #{cfg.space}"
          client.chat_postMessage(channel: cfg.channel, text: msg,  as_user: true)
        end
        log "Finished"
      end
    end
  end
end
