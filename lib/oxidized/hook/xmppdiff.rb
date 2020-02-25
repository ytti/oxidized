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
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    begin
      Timeout.timeout(15) do
        gitoutput = ctx.node.output.new
        diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil

        interesting = diff[:patch].lines.to_a[4..-1].any? do |line|
          ["+", "-"].include?(line[0]) && (not ["#", "!"].include?(line[1]))
        end
        interesting &&= diff[:patch].lines.to_a[5..-1].any? { |line| line[0] == '-' }
        interesting &&= diff[:patch].lines.to_a[5..-1].any? { |line| line[0] == '+' }

        if interesting
          log "Connecting to XMPP"
          client = Jabber::Client.new(Jabber::JID.new(cfg.jid))
          client.connect
          sleep 1
          client.auth(cfg.password)
          sleep 1

          log "Connected"

          m = Jabber::MUC::SimpleMUCClient.new(client)
          m.join(cfg.channel + "/" + cfg.nick)

          log "Joined"

          title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
          log "Posting diff as snippet to #{cfg.channel}"

          m.say(title + "\n\n" + diff[:patch].lines.to_a[4..-1].join)

          sleep 1

          client.close

          log "Finished"

        end
      end
    rescue Timeout::Error
      log "timed out"
    end
  end
end
