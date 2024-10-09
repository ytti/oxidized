module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  class Manager
    class << self
      def load(dir, file)
        require File.join dir, file + '.rb'
        klass = nil
        [Oxidized, Source, Object].each do |mod|
          klass   = mod.constants.find { |const| const.to_s.casecmp(file).zero? }
          klass ||= mod.constants.find { |const| const.to_s.downcase == 'oxidized' + file.downcase }
          klass   = mod.const_get klass if klass
          break if klass
        end
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
      loader @input, Config::INPUT_DIR, "input", name
    end

    def add_output(name)
      loader @output, Config::OUTPUT_DIR, "output", name
    end

    def add_source(name)
      loader @source, Config::SOURCE_DIR, "source", name
    end

    def add_model(name)
      loader @model, Config::MODEL_DIR, "model", name
    end

    def add_hook(name)
      loader @hook, Config::HOOK_DIR, "hook", name
    end

    private

    # if local version of file exists, load it, else load global - return falsy value if nothing loaded
    def loader(hash, global_dir, local_dir, name)
      dir   = File.join(Config::ROOT, local_dir)
      map   = Manager.load(dir, name) if File.exist? File.join(dir, name + ".rb")
      map ||= Manager.load(global_dir, name)
      hash.merge!(map) if map
    end
  end
end
