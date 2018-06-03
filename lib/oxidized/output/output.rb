module Oxidized
  class Output
    class NoConfig < OxidizedError; end

    def cfg_to_str cfg
      cfg.select { |h| h[:type] == 'cfg' }.map { |h| h[:data] }.join
    end

    def name node
      name_str = Oxidized.config.output.name?
      return node.name unless name_str
      time = Time.now.utc
      map = {
        name:   node.name,
        ip:     node.ip,
        model:  node.model.class.inspect.downcase,
        group:  node.group,
        year:   time.year,
        month:  "%02d" % time.month,
        day:    "%02d" % time.day,
        hour:   "%02d" % time.hour,
        minute: "%02d" % time.min,
        second: "%02d" % time.sec,
      }
      name_str % map
    end
  end
end
