require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

class XMPPDiff < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.jid is required' unless cfg.has_key?('jid')
    raise KeyError, 'hook.password is required' unless cfg.has_key?('password')
    raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
    raise KeyError, 'hook.nick is required' unless cfg.has_key?('nick')
 end

  def run_hook(ctx)
    if ctx.node
      if ctx.event.to_s == "post_store"

        log "Connecting to XMPP"
        client = Jabber::Client.new(Jabber::JID.new(cfg.jid))
        client.connect
        client.auth(cfg.password)

        log "Connected"

        m = Jabber::MUC::SimpleMUCClient.new(client)
        m.join(cfg.channel + "/" + cfg.nick)

        log "Joined"

        gitoutput = ctx.node.output.new
        diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
        title = "#{ctx.node.name.to_s} #{ctx.node.group.to_s} #{ctx.node.model.class.name.to_s.downcase}"
        log "Posting diff as snippet to #{cfg.channel}"

        m.say(title)
        m.say(diff[:patch].lines.to_a[4..-1].join)

        client.close

        log "Finished"
      end
    end
  end
end
