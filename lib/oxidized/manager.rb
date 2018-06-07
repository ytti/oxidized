module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  class Manager
    class << self
      def load dir, file
        require File.join dir, file + '.rb'
        klass = nil
        [Oxidized, Object].each do |mod|
          klass = mod.constants.find { |const| const.to_s.downcase == file.downcase }
          klass = mod.constants.find { |const| const.to_s.downcase == 'oxidized' + file.downcase } unless klass
          klass = mod.const_get klass if klass
          break if klass
        end
        i = klass.new
        i.setup if i.respond_to? :setup
        { file => klass }
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

    def add_input name
      @input.merge! Manager.load(Config::InputDir, name)
    end

    def add_output name
      @output.merge! Manager.load(Config::OutputDir, name)
    end

    def add_source name
      return nil if @source.has_key? name
      @source.merge Manager.load(Config::SourceDir, name)
    end

    def add_model name
      @model.merge! local_load("model", name) ||
                    Manager.load(Config::ModelDir, name)
    end

    def add_hook name
      return nil if @hook.has_key? name
      @model.merge! local_load("hook", name) ||
                    Manager.load(Config::HookDir, name)
    end

    private

    # try to load locally defined file, instead of upstream provided
    def local_load dir, name
      dir = File.join(Config::Root, dir)
      return false unless File.exist? File.join(dir, name + ".rb")
      Manager.load dir, name
    end
  end
end
