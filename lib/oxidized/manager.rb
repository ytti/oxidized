module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  class Manager
    class << self
      def load dir, file
        require File.join dir, file+'.rb'
        obj, Oxidized.mgr.loader =  Oxidized.mgr.loader, nil
        k = obj[:class].new
        k.setup if k.respond_to? :setup
        { file => obj[:class] }
      end
    end
    attr_reader :input, :output, :model, :source
    attr_accessor :loader
    def initialize
      @input  = {}
      @output = {}
      @model  = {}
      @source = {}
    end
    def input= method
      method = Manager.load Config::InputDir, method
      return false if method.empty?
      @input.merge! method
    end
    def output= method
      method = Manager.load Config::OutputDir, method
      return false if method.empty?
      @output.merge! method
    end
    def model= _model
      _model = Manager.load Config::ModelDir, _model
      return false if _model.empty?
      @model.merge! _model 
    end
    def source= _source
      return nil if @source.key? _source
      _source = Manager.load Config::SourceDir, _source
      return false if _source.empty?
      @source.merge! _source
    end
  end
end
