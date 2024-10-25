module Oxidized
  module Models
    class AsterNOS < Oxidized::Models::Model
      using Refinements

      prompt /^[^\$]+\$/
      comment '# '

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-2].join
      end

      cmd 'show version' do |cfg|
        # @!visibility private
        # @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
        comment cfg
      end

      cmd "show runningconfiguration all"

      cfg :ssh do
        # @!visibility private
        # exec true
        pre_logout 'exit'
      end
    end
  end
end
