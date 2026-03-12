module Oxidized
  module Hooks
    class Ruby < Oxidized::Hook
      def validate_cfg!
        raise ArgumentError, "ruby hook requires 'file'" unless cfg.has_key?('file')

        file = File.expand_path(cfg.file)
        raise ArgumentError, "ruby hook file not found: #{file}" unless File.exist?(file)

        instance_eval(File.read(file), file)
      end

      def run_hook(ctx)
        send(ctx.event, ctx) if respond_to?(ctx.event)
      end
    end
  end
end
