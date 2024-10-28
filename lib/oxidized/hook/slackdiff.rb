module Oxidized
  module Hook
    require 'slack_ruby_client'

    # The SlackDiff class is an implementation of an Oxidized hook that sends configuration change
    # notifications to a specified Slack channel, defaults to posting a diff, if messageformat is
    # supplied them a message will be posted too diff defaults to true.
    #
    # This class is particularly useful for teams using Slack for collaboration, allowing them
    # to receive real-time updates about configuration changes in their network devices, thus
    # improving communication and operational responsiveness.

    class SlackDiff < Oxidized::Hook
      # Validates the configuration for the SlackDiff hook.
      #
      # @raise [KeyError] if `hook.token` or `hook.channel` is missing from the configuration.
      def validate_cfg!
        raise KeyError, 'hook.token is required' unless cfg.has_key?('token')
        raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
      end

      # Executes the hook when a configuration change is detected.
      #
      # @param ctx [Object] The context object containing details about the event and the node.
      #
      # @return [void]
      #
      # @note
      # This method connects to Slack using the provided token and checks the authentication.
      # It retrieves and posts the configuration diff to the specified channel and posts a
      # custom message if defined in the configuration.
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
            log "Posting diff as snippet to #{cfg.channel}"
            client.files_upload(channels: cfg.channel, as_user: true,
                                content: diff[:patch].lines.to_a[4..-1].join,
                                filetype: "diff",
                                title: title,
                                filename: "change")
          end
        end
        # @!visibility private
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
  end
end
