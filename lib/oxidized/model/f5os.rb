module Oxidized
  module Models
    # @!visibility private
    # frozen_string_literal: true

    class F5OS < Oxidized::Models::Model
      # @!visibility private
      # F5OS Model #

      comment '!'
      prompt(/^([\w.@()-]+ ?[#>]\s+)$/)

      cmd 'show running-config'

      cfg :ssh do
        post_login do
          cmd 'paginate false'
        end
        pre_logout 'exit'
      end
    end
  end
end
