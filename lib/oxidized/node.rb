module Oxidized
  require 'resolv'
  require 'ostruct'
  require_relative 'node/stats'
  require 'oxidized/error/methodnotfound'
  require 'oxidized/error/modelnotfound'

  class Node
    # @!attribute [rw] name
    #   @return [String] The name of the node.
    attr_reader :name

    # @!attribute [rw] ip
    #   @return [String] The IP address of the node.
    attr_reader :ip

    # @!attribute [rw] model
    #   @return [Model] The model associated with the node.
    attr_reader :model

    # @!attribute [rw] input
    #   @return [Input] The input method for the node.
    attr_reader :input

    # @!attribute [rw] output
    #   @return [Output] The output method for the node.
    attr_reader :output

    # @!attribute [rw] group
    #   @return [String] The group to which the node belongs.
    attr_reader :group

    # @!attribute [rw] auth
    #   @return [Hash] Authentication information for the node.
    attr_reader :auth

    # @!attribute [rw] prompt
    #   @return [String] The prompt used for interaction with the node.
    attr_reader :prompt

    # @!attribute [rw] vars
    #   @return [Hash] Variables specific to the node.
    attr_reader :vars

    # @!attribute [rw] last
    #   @return [Job] The last job executed for the node.
    attr_reader :last

    # @!attribute [rw] repo
    #   @return [String] The repository associated with the node.
    attr_reader :repo

    # @!attribute [rw] running
    #   @return [Boolean] Indicates if the node is currently running.
    attr_accessor :running

    # @!attribute [rw] user
    #   @return [String] The user associated with the node.
    attr_accessor :user

    # @!attribute [rw] email
    #   @return [String] The email associated with the node.
    attr_accessor :email

    # @!attribute [rw] msg
    #   @return [String] A message related to the node's status.
    attr_accessor :msg

    # @!attribute [rw] from
    #   @return [String] The source from which the node was created.
    attr_accessor :from

    # @!attribute [rw] stats
    #   @return [Stats] Statistics related to the node's operations.
    attr_accessor :stats

    # @!attribute [rw] retry
    #   @return [Integer] The number of retries attempted for the node.
    attr_accessor :retry

    # @!attribute [rw] err_type
    #   @return [String] The type of the last error encountered.
    attr_accessor :err_type

    # @!attribute [rw] err_reason
    #   @return [String] The reason for the last error encountered.
    attr_accessor :err_reason
    alias running? running

    # Initializes a new node with given options.
    #
    # @param opt [Hash] The options for initializing the node.
    # @option opt [String] :name The name of the node.
    # @option opt [String] :ip The IP address of the node.
    # @option opt [String] :group The group of the node.
    # @option opt [Hash] :vars Variables associated with the node.
    #
    # @return [void]
    def initialize(opt)
      Oxidized.logger.debug 'resolving DNS for %s...' % opt[:name]
      # @!visibility private
      # remove the prefix if an IP Address is provided with one as IPAddr converts it to a network address.
      ip_addr, = opt[:ip].to_s.split("/")
      Oxidized.logger.debug 'IPADDR %s' % ip_addr.to_s
      @name = opt[:name]
      @ip = IPAddr.new(ip_addr).to_s rescue nil
      @ip ||= Resolv.new.getaddress(@name) if Oxidized.config.resolve_dns?
      @ip ||= @name
      @group = opt[:group]
      @model = resolve_model(opt)
      @input = resolve_input(opt)
      @output = resolve_output(opt)
      @auth = resolve_auth(opt)
      @prompt = resolve_prompt(opt)
      @vars = opt[:vars]
      @stats = Stats.new
      @retry = 0
      @repo = resolve_repo(opt)
      @err_type = nil
      @err_reason = nil

      # @!visibility private
      # model instance needs to access node instance
      @model.node = self
    end

    # Runs the input method for the node and returns the status and configuration.
    #
    # @return [Array<Symbol, Object>] The status and configuration.
    def run
      status, config = :fail, nil
      @input.each do |input|
        # @!visibility private
        # don't try input if model is missing config block, we may need strong config to class_name map
        cfg_name = input.to_s.split('::').last.downcase
        next unless @model.cfg[cfg_name] && (not @model.cfg[cfg_name].empty?)

        @model.input = input = input.new
        if (config = run_input(input))
          Oxidized.logger.debug "lib/oxidized/node.rb: #{input.class.name} ran for #{name} successfully"
          status = :success
          break
        else
          Oxidized.logger.debug "lib/oxidized/node.rb: #{input.class.name} failed for #{name}"
          status = :no_connection
        end
      end
      @model.input = nil
      [status, config]
    end

    # Runs a specific input method and handles exceptions.
    #
    # @param input [Input] The input method to run.
    #
    # @return [Boolean] True if successful, false otherwise.
    def run_input(input)
      rescue_fail = {}
      [input.class::RESCUE_FAIL, input.class.superclass::RESCUE_FAIL].each do |hash|
        hash.each do |level, errors|
          errors.each do |err|
            rescue_fail[err] = level
          end
        end
      end
      begin
        input.connect(self) && input.get
      rescue *rescue_fail.keys => err
        resc = ''
        unless (level = rescue_fail[err.class])
          resc  = err.class.ancestors.find { |e| rescue_fail.has_key?(e) }
          level = rescue_fail[resc]
          resc  = " (rescued #{resc})"
        end
        Oxidized.logger.send(level, '%s raised %s%s with msg "%s"' % [ip, err.class, resc, err.message])
        @err_type = err.class.to_s
        @err_reason = err.message.to_s
        false
      rescue StandardError => e
        # @!visibility private
        # Send a message in debug mode in case we are not able to create a crashfile
        Oxidized.logger.send(:debug, '%s raised %s with msg "%s", creating crashfile' % [ip, e.class, e.message])
        crashdir  = Oxidized.config.crash.directory
        crashfile = Oxidized.config.crash.hostnames? ? name : ip.to_s
        FileUtils.mkdir_p(crashdir) unless File.directory?(crashdir)

        File.open File.join(crashdir, crashfile), 'w' do |fh|
          fh.puts Time.now.utc
          fh.puts e.message + ' [' + e.class.to_s + ']'
          fh.puts '-' * 50
          fh.puts e.backtrace
        end
        Oxidized.logger.error '%s raised %s with msg "%s", %s saved' % [ip, e.class, e.message, crashfile]
        @err_type = e.class.to_s
        @err_reason = e.message.to_s
        false
      end
    end

    # Serializes the node's information into a hash.
    #
    # @return [Hash] The serialized node information.
    def serialize
      h = {
        name:      @name,
        full_name: @name,
        ip:        @ip,
        group:     @group,
        model:     @model.class.to_s,
        last:      nil,
        vars:      @vars,
        mtime:     @stats.mtime
      }
      h[:full_name] = [@group, @name].join('/') if @group
      if @last
        h[:last] = {
          start:  @last.start,
          end:    @last.end,
          status: @last.status,
          time:   @last.time
        }
      end
      h
    end

    # Sets the last job for the node.
    #
    # @param job [Job] The job to set as last.
    #
    # @return [void]
    def last=(job)
      if job
        ostruct = OpenStruct.new
        ostruct.start  = job.start
        ostruct.end    = job.end
        ostruct.status = job.status
        ostruct.time   = job.time
        @last = ostruct
      else
        @last = nil
      end
    end

    # Resets the node's state.
    #
    # @return [void]
    def reset
      @user = @email = @msg = @from = nil
      @retry = 0
    end

    # Updates the modification time for the node's statistics.
    #
    # @return [void]
    def modified
      @stats.update_mtime
    end

    private

    # Resolves the prompt for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [String] The resolved prompt.
    def resolve_prompt(opt)
      opt[:prompt] || @model.prompt || Oxidized.config.prompt
    end

    # Resolves the authentication for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [Hash] The resolved authentication information.
    def resolve_auth(opt)
      # Resolve configured username/password
      {
        username: resolve_key(:username, opt),
        password: resolve_key(:password, opt)
      }
    end

    # Resolves the input methods for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [Array<Input>] The resolved input methods.
    def resolve_input(opt)
      inputs = resolve_key :input, opt, Oxidized.config.input.default
      inputs.split(/\s*,\s*/).map do |input|
        Oxidized.mgr.add_input(input) || raise(Error::MethodNotFound, "#{input} not found for node #{ip}") unless Oxidized.mgr.input[input]

        Oxidized.mgr.input[input]
      end
    end

    # Resolves the output method for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [Output] The resolved output method.
    def resolve_output(opt)
      output = resolve_key :output, opt, Oxidized.config.output.default
      Oxidized.mgr.add_output(output) || raise(Error::MethodNotFound, "#{output} not found for node #{ip}") unless Oxidized.mgr.output[output]

      Oxidized.mgr.output[output]
    end

    # Resolves the model for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [Model] The resolved model.
    def resolve_model(opt)
      model = resolve_key :model, opt
      @model_name = model
      unless Oxidized.mgr.model[model]
        Oxidized.logger.debug "lib/oxidized/node.rb: Loading model #{model.inspect}"
        Oxidized.mgr.add_model(model) || raise(ModelNotFound, "#{model} not found for node #{ip}")
      end
      Oxidized.mgr.model[model].new
    end

    # Resolves the repository for the node.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [String, nil] The resolved repository.
    def resolve_repo(opt)
      type = git_type opt
      return nil unless type

      remote_repo = Oxidized.config.output.send(type).repo
      if remote_repo.is_a?(::String)
        if Oxidized.config.output.send(type).single_repo? || @group.nil?
          remote_repo
        else
          File.join(File.dirname(remote_repo), @group + '.git')
        end
      else
        remote_repo[@group]
      end
    end

    # Resolves a specific key for the node based on various priorities.
    # The priority is as follows: node -> group specific model -> group -> model -> global passed -> global
    # where node has the highest priority (= if defined, overwrites other values)
    #
    # @param key [Symbol] The key to resolve.
    # @param opt [Hash] Options for the node.
    # @param global [Object] A global value to use if no specific value is found.
    #
    # @return [Object] The resolved value.
    def resolve_key(key, opt, global = nil)
      # The priority is as follows: node -> group specific model -> group -> model -> global passed -> global
      key_sym = key.to_sym
      key_str = key.to_s
      model_name = @model_name
      Oxidized.logger.debug "node.rb: resolving node key '#{key}', with passed global value of '#{global}' and node value '#{opt[key_sym]}'"

      # Node
      if opt[key_sym]
        value = opt[key_sym]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from node"

      # Group specific model
      elsif Oxidized.config.groups.has_key?(@group) && Oxidized.config.groups[@group].models.has_key?(model_name) && Oxidized.config.groups[@group].models[model_name].has_key?(key_str)
        value = Oxidized.config.groups[@group].models[model_name][key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from model in group"

      # Group
      elsif Oxidized.config.groups.has_key?(@group) && Oxidized.config.groups[@group].has_key?(key_str)
        value = Oxidized.config.groups[@group][key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from group"

      # Model
      elsif Oxidized.config.models.has_key?(model_name) && Oxidized.config.models[model_name].has_key?(key_str)
        value = Oxidized.config.models[model_name][key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from model"

      # Global passed
      elsif global
        value = global
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from passed global value"

      # Global
      elsif Oxidized.config.has_key?(key_str)
        value = Oxidized.config[key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from global"
      end
      value
    end

    # Determines if the output type is a Git repository.
    #
    # @param opt [Hash] Options for the node.
    #
    # @return [String, nil] The Git repository type or `nil` if not a Git type.
    def git_type(opt)
      type = opt[:output] || Oxidized.config.output.default
      return nil unless type[0..2] == "git"

      type
    end
  end
end
