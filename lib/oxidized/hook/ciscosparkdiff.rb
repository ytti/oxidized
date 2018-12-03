require 'cisco_spark'

# defaults to posting a diff, if messageformat is supplied them a message will be posted too
# diff defaults to true
# Modified from slackdiff

class CiscoSparkDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.accesskey is required' unless cfg.has_key?('accesskey')
    raise KeyError, 'hook.space is required' unless cfg.has_key?('space')
  end

  def run_hook(ctx)
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    log "Connecting to Cisco Spark"
    CiscoSpark.configure do |config|
      config.api_key = cfg.accesskey
      config.proxy = cfg.proxy if cfg.has_key?('proxy')
    end
    room = CiscoSpark::Room.new(id: cfg.space)
    log "Connected"

    if cfg.has_key?("diff") ? cfg.diff : true
      gitoutput = ctx.node.output.new
      diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
      title = ctx.node.name.to_s
      log "Posting diff as snippet to #{cfg.space}"
      room.send_message CiscoSpark::Message.new(text: 'Device ' + title + ' modified:' + "\n" + diff[:patch].lines.to_a[4..-1].join)
    end

    if cfg.message?
      log cfg.message
      msg = cfg.message % { node: ctx.node.name.to_s, group: ctx.node.group.to_s, commitref: ctx.commitref, model: ctx.node.model.class.name.to_s.downcase }
      log msg
      log "Posting message to #{cfg.space}"
      room.send_message CiscoSpark::Message.new(text: msg)
    end

    log "Finished"
  end
end
