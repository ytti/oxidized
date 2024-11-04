module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  class Manager
    class << self
      def load(dir, file, namespace)
        require File.join dir, file + '.rb'

        # Search the object to load in namespace
        klass = namespace.constants.find { |const| const.to_s.casecmp(file).zero? }

        return false unless klass

        klass = namespace.const_get klass

        i = klass.new
        i.setup if i.respond_to? :setup
        { file => klass }
      rescue LoadError
        false
      end
    end

    attr_reader :input, :output, :source, :model, :hook

    def initialize
      @input  = {}
      @output = {}
      @source = {}
      @model  = {}
      @hook   = {}
    end

    def add_input(name)
      loader @input, Config::INPUT_DIR, "input", name, Oxidized
    end

    def add_output(name)
      loader @output, Config::OUTPUT_DIR, "output", name, Oxidized::Output
    end

    def add_source(name)
      loader @source, Config::SOURCE_DIR, "source", name, Oxidized::Source
    end

    def add_model(name)
      loader @model, Config::MODEL_DIR, "model", name, Object
    end

    def add_hook(name)
      loader @hook, Config::HOOK_DIR, "hook", name, Object
    end

    private

    # if local version of file exists, load it, else load global - return falsy value if nothing loaded
    def loader(hash, global_dir, local_dir, name, namespace)
      dir   = File.join(Config::ROOT, local_dir)
      map   = Manager.load(dir, name, namespace) if File.exist? File.join(dir, name + ".rb")
      map ||= Manager.load(global_dir, name, namespace)
      hash.merge!(map) if map
    end
  end
end
