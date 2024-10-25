module Oxidized
  module Models
    class OneFinity < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Fujitsu 1finity

      prompt /(\r?[\w.@_()-]+[>]\s?)$/

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-3].join
      end

      cmd 'show configuration | display set | nomore'

      cfg :ssh do
        pre_logout 'exit'
        exec true
      end
    end
  end
end
