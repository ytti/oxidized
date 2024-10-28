module Oxidized
  module Hook
    require 'aws-sdk'

    # The AwsSns class is an implementation of an Oxidized hook that integrates with Amazon
    # Simple Notification Service (SNS) to send notifications about events related to network
    # device configurations.
    #
    # This class is useful for organizations that use AWS SNS for notification management,
    # enabling automated alerts about configuration changes or events within their network
    # infrastructure, thereby facilitating timely responses and better operational awareness.
    class AwsSns < Oxidized::Hook
      # Validates the configuration for the AwsSns hook.
      #
      # This method checks if the necessary configuration options are provided.
      # Raises an error if any required configuration is missing.
      #
      # @raise [KeyError] if 'region' or 'topic_arn' is not provided in the configuration.
      def validate_cfg!
        raise KeyError, 'hook.region is required' unless cfg.has_key?('region')
        raise KeyError, 'hook.topic_arn is required' unless cfg.has_key?('topic_arn')
      end

      # Executes the hook, sending a notification to the specified SNS topic.
      #
      # @param ctx [HookContext] the context in which the hook is executed, containing event and node information.
      # @return [void]
      def run_hook(ctx)
        sns = Aws::SNS::Resource.new(region: cfg.region)
        topic = sns.topic(cfg.topic_arn)
        message = {
          event: ctx.event.to_s
        }
        if ctx.node
          message.merge!(
            group: ctx.node.group.to_s,
            model: ctx.node.model.class.name.to_s.downcase,
            node:  ctx.node.name.to_s
          )
        end
        topic.publish(
          message: message.to_json
        )
      end
    end
  end
end
