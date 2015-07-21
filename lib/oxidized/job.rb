module Oxidized
  require 'oxidized/store'
  class Job < Thread
    attr_reader :start, :end, :status, :time, :node, :config
    def initialize node
      @node         = node
      
      store = Store.new
      #store stats in sql database and return a hashmap

      super do |node|
        hash = store.update_stats node
        @start        = hash[:start]
        @status       = hash[:status]
        @config       = hash[:config]
        @end          = hash[:end]
        @time         = hash[:time]
      end
    end
  end
end
