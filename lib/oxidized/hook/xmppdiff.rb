module Oxidized
  module Hook
    require 'xmpp4r'
    require 'xmpp4r/muc/helper/simplemucclient'

    # The XMPPDiff class is an implementation of an Oxidized hook that integrates with XMPP
    # (Extensible Messaging and Presence Protocol) to send notifications about configuration
    # changes in network devices.
    #
    # This hook connects to an XMPP chat room (MUC) and posts diffs of configuration changes
    # for network devices, allowing team members to be notified in real-time.
    class XMPPDiff < Oxidized::Hook
      # Establishes a connection to the XMPP server and joins the specified chat room.
      #
      # @return [void]
      def connect
        @client = Jabber::Client.new(Jabber::JID.new(cfg.jid))

        log "Connecting to XMPP"
        begin
          Timeout.timeout(15) do
            begin
              @client.connect
            rescue StandardError => e
              log "Failed to connect to XMPP: #{e}"
            end
            sleep 1

            log "Authenticating to XMPP"
            @client.auth(cfg.password)
            sleep 1

            log "Connected to XMPP"

            @muc = Jabber::MUC::SimpleMUCClient.new(@client)
            @muc.join(cfg.channel + "/" + cfg.nick)

            log "Joined #{cfg.channel}"
          end
        rescue Timeout::Error
          log "timed out"
          @client = nil
          @muc = nil
        end

        @client.on_exception do
          log "XMPP connection aborted, reconnecting"
          @client = nil
          @muc = nil
          connect
        end
      end

      # Validates the configuration for the XMPPDiff hook.
      #
      # @raise [KeyError] if `hook.jid`, `hook.password`, `hook.channel`, or `hook.nick` is missing.
      def validate_cfg!
        raise KeyError, 'hook.jid is required' unless cfg.has_key?('jid')
        raise KeyError, 'hook.password is required' unless cfg.has_key?('password')
        raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
        raise KeyError, 'hook.nick is required' unless cfg.has_key?('nick')
      end

      # Executes the hook when a configuration change is detected.
      #
      # @param ctx [Object] The context object containing details about the event and the node.
      #
      # @return [void]
      #
      # @note
      # This method connects to the XMPP server if not already connected and checks for
      # interesting changes in the configuration diff. If changes are found, it posts the
      # diff to the specified XMPP chat room.
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

              # @!visibility private
              # Maybe connecting failed, so only proceed if we actually joined the MUC
              unless @muc.nil?
                title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
                log "Posting diff as snippet to #{cfg.channel}"

                @muc.say(title + "\n\n" + diff[:patch].lines.to_a[4..-1].join)
              end
            end
          end
        rescue Timeout::Error
          log "timed out"
        end
      end
    end
  end
end
