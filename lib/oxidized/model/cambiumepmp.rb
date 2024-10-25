module Oxidized
  module Models
    class CambiumePMP < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Cambium ePMP Radios

      prompt /.*>/

      cmd :all do |cfg|
        cfg.cut_both
      end

      pre do
        cmd 'config show json'
      end

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
