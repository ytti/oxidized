module Oxidized
  module Output
    def self.clean_obsolete_nodes(active_nodes)
      return unless Oxidized.config.output.clean_obsolete_nodes?

      output_name = Oxidized.config.output.default
      output = Oxidized.mgr.add_output output_name
      output[output_name].clean_obsolete_nodes(active_nodes)
    end

    class Output
      include SemanticLogger::Loggable

      class NoConfig < OxidizedError; end

      def cfg_to_str(cfg)
        cfg.select { |h| h[:type] == 'cfg' }.map { |h| h[:data] }.join
      end

      def self.clean_obsolete_nodes(_active_nodes)
        logger.warn "clean_obsolete_nodes is not implemented for #{name}"
      end
    end
  end
end
