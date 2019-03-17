module Oxidized
  class Output
    class NoConfig < OxidizedError; end

    def cfg_to_str(cfg)
      cfg.select { |h| h[:type] == 'cfg' }.map { |h| h[:data] }.join
    end
  end
end
