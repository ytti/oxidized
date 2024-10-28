module Oxidized
  module Hook
    require 'cisco_spark'

    # defaults to posting a diff, if messageformat is supplied them a message will be posted too
    # diff defaults to true
    # Modified from slackdiff

    # The CiscoSparkDiff class is an implementation of an Oxidized hook that integrates
    # with Cisco Spark (now part of Cisco Webex) to send notifications about configuration
    # changes in network devices.
    #
    # This class is useful for teams that utilize Cisco Spark for collaboration, allowing
    # them to receive real-time updates on configuration changes directly in their chat
    # rooms, thus enhancing visibility and coordination among team members.
    class CiscoSparkDiff < Oxidized::Hook
      # Validates the configuration for the CiscoSparkDiff hook.
      #
      # This method checks if the necessary configuration options are provided.
      # Raises an error if any required configuration is missing.
      #
      # @raise [KeyError] if 'accesskey' or 'space' is not provided in the configuration.
      def validate_cfg!
        raise KeyError, 'hook.accesskey is required' unless cfg.has_key?('accesskey')
        raise KeyError, 'hook.space is required' unless cfg.has_key?('space')
      end

      # Executes the hook, posting a configuration diff and an optional message to the specified Cisco Spark room.
      #
      # @param ctx [HookContext] the context in which the hook is executed, containing event and node information.
      # @return [void]
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
  end
end
