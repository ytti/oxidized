module Oxidized
  class Model
    class Outputs

      def to_cfg
        type_to_str('cfg')
      end

      def type_to_str want_type
        type(want_type).map { |h| h[:output] }.join
      end

      def each_type &block
        types.each do |want_type|
          yield [want_type, type(want_type)]
        end
      end

      def << output
        @outputs << output
      end

      def all
        @outputs
      end

      def type type
        @outputs.select { |h| h[:type]==type }
      end

      def types
        @outputs.map { |h| h[:type] }.uniq
      end

      private

      def initialize
        @outputs = []
      end

    end
  end
end
