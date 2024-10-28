module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'

  # Manages the loading and configuration of input, output, source, model, and hook components for Oxidized.
  #
  # This class is responsible for dynamically loading components based on the configuration
  # and providing access to the loaded components.
  class Manager
    class << self
      # Loads a component from the specified directory and file name.
      #
      # @param dir [String] The directory to load the component from.
      # @param file [String] The base file name of the component to load (without extension).
      # @return [Hash, false] A hash containing the file name and class if loaded successfully,
      #   or false if the component could not be loaded.
      def load(dir, file)
        puts "Loading file: #{File.join(dir, file + '.rb')}"
        require File.join(dir, file + '.rb')
        klass = nil
        [Oxidized::Models, Oxidized::Input, Oxidized::Output, Oxidized::Source, Oxidized::Hook, Oxidized::Error, Oxidized, Object].each do |mod|
          klass   = mod.constants.find { |const| const.to_s.casecmp(file).zero? }
          klass ||= mod.constants.find { |const| const.to_s.downcase == 'oxidized' + file.downcase }
          klass   = mod.const_get(klass) if klass
          break if klass
        end
        puts "Class found: #{klass}"
        i = klass.new
        i.setup if i.respond_to?(:setup)
        { file => klass }
      rescue LoadError
        puts "LoadError: Could not load file"
        false
      rescue NoMethodError => e
        puts "NoMethodError: #{e.message}"
        false
      end
    end

    # @!attribute [rw] input
    #   @return [Hash] input handlers
    attr_reader :input

    # @!attribute [rw] output
    #   @return [Hash] output handlers
    attr_reader :output

    # @!attribute [rw] source
    #   @return [Hash] source handlers
    attr_reader :source

    # @!attribute [rw] model
    #   @return [Hash] model handlers
    attr_reader :model

    # @!attribute [rw] hook
    #   @return [Hash] hook handlers
    attr_reader :hook

    # Initializes a new instance of the Manager class, setting up empty hashes for components.
    def initialize
      @input  = {}
      @output = {}
      @source = {}
      @model  = {}
      @hook   = {}
    end

    # Adds an input component to the manager.
    #
    # @param name [String] The name of the input component to add.
    def add_input(name)
      loader @input, Config::INPUT_DIR, "input", name
    end

    # Adds an output component to the manager.
    #
    # @param name [String] The name of the output component to add.
    def add_output(name)
      loader @output, Config::OUTPUT_DIR, "output", name
    end

    # Adds a source component to the manager.
    #
    # @param name [String] The name of the source component to add.
    def add_source(name)
      loader @source, Config::SOURCE_DIR, "source", name
    end

    # Adds a model component to the manager.
    #
    # @param name [String] The name of the model component to add.
    def add_model(name)
      loader @model, Config::MODEL_DIR, "model", name
    end

    # Adds a hook component to the manager.
    #
    # @param name [String] The name of the hook component to add.
    def add_hook(name)
      loader @hook, Config::HOOK_DIR, "hook", name
    end

    private

    # Loads a component from a local or global directory.
    #
    # @param hash [Hash] The hash to store the loaded component.
    # @param global_dir [String] The global directory to load from.
    # @param local_dir [String] The local directory to load from.
    # @param name [String] The name of the component to load.
    # @return [void]
    def loader(hash, global_dir, local_dir, name)
      dir   = File.join(Config::ROOT, local_dir)
      map   = Manager.load(dir, name) if File.exist? File.join(dir, name + ".rb")
      map ||= Manager.load(global_dir, name)
      hash.merge!(map) if map
    end
  end
end
