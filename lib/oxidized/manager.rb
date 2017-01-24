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
            klass = mod.constants.find { |const| const.to_s.downcase == 'oxidized'+ file.downcase } unless klass
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
    attr_reader :input, :output, :model, :source, :hook
    def initialize
      @input  = {}
      @output = {}
      @model  = {}
      @source = {}
      @hook = {}
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
      name = _model
      _model = Manager.load File.join(Config::Root, 'model'), name
      _model = Manager.load Config::ModelDir, name if _model.empty?
      return false if _model.empty?
      @model.merge! _model
    end
    def add_source _source
      return nil if @source.key? _source
      _source = Manager.load Config::SourceDir, _source
      return false if _source.empty?
      @source.merge! _source
    end
    def add_hook _hook
      return nil if @hook.key? _hook
      name = _hook
      _hook = Manager.load File.join(Config::Root, 'hook'), name
      _hook = Manager.load Config::HookDir, name if _hook.empty?
      return false if _hook.empty?
      @hook.merge! _hook
    end
  end
end
