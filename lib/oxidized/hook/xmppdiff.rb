require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

class XMPPDiff < Oxidized::Hook
  def connect
    @client = Jabber::Client.new(Jabber::JID.new(cfg.jid))

    logger.info "Connecting to XMPP"
    begin
      Timeout.timeout(15) do
        begin
          @client.connect
        rescue StandardError => e
          logger.info "Failed to connect to XMPP: #{e}"
        end
        sleep 1

        logger.info "Authenticating to XMPP"
        @client.auth(cfg.password)
        sleep 1

        logger.info "Connected to XMPP"

        @muc = Jabber::MUC::SimpleMUCClient.new(@client)
        @muc.join(cfg.channel + "/" + cfg.nick)

        logger.info "Joined #{cfg.channel}"
      end
    rescue Timeout::Error
      logger.info "timed out"
      @client = nil
      @muc = nil
    end

    @client.on_exception do
      logger.info "XMPP connection aborted, reconnecting"
      @client = nil
      @muc = nil
      connect
    end
  end

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

        if interesting
          connect if @muc.nil?

          # Maybe connecting failed, so only proceed if we actually joined the MUC
          unless @muc.nil?
            title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
            logger.info "Posting diff as snippet to #{cfg.channel}"

            @muc.say(title + "\n\n" + diff[:patch].lines.to_a[4..-1].join)
          end
        end
      end
    rescue Timeout::Error
      logger.info "timed out"
    end
  end
end
