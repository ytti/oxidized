module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  class Manager
    class << self
      def load dir, file
        begin
          require File.join dir, file+'.rb'
          klass = nil
          [Oxidized, Object].each do |mod|
            klass = mod.constants.find { |const| const.to_s.downcase == file.downcase }
            klass = mod.const_get klass if klass
            break if klass
          end
          i = klass.new
          i.setup if i.respond_to? :setup
          { file => klass }
        rescue LoadError
          {}
        end
      end
    end
    attr_reader :input, :output, :model, :source
    def initialize
      @input  = {}
      @output = {}
      @model  = {}
      @source = {}
    end
    def add_input method
      method = Manager.load Config::InputDir, method
      return false if method.empty?
      @input.merge! method
    end
    def add_output method
      method = Manager.load Config::OutputDir, method
      return false if method.empty?
      @output.merge! method
    end
    def add_model _model
      _model = Manager.load Config::ModelDir, _model
      return false if _model.empty?
      @model.merge! _model
    end
    def add_source _source
      return nil if @source.key? _source
      _source = Manager.load Config::SourceDir, _source
      return false if _source.empty?
      @source.merge! _source
    end
  end
end
