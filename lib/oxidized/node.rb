module Oxidized
  require 'resolv'
  require 'ostruct'
  require_relative 'node/stats'
  class MethodNotFound < OxidizedError; end
  class ModelNotFound  < OxidizedError; end
  class Node
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt, :vars, :last, :repo
    attr_accessor :running, :user, :email, :msg, :from, :stats, :retry
    alias running? running

    def initialize(opt)
      Oxidized.logger.debug 'resolving DNS for %s...' % opt[:name]
      # remove the prefix if an IP Address is provided with one as IPAddr converts it to a network address.
      ip_addr, = opt[:ip].to_s.split("/")
      Oxidized.logger.debug 'IPADDR %s' % ip_addr.to_s
      @name = opt[:name]
      @ip = IPAddr.new(ip_addr).to_s rescue nil
      @ip ||= Resolv.new.getaddress(@name) if Oxidized.config.resolve_dns?
      @ip ||= @name
      @group = opt[:group]
      @model = resolve_model opt
      @input = resolve_input opt
      @output = resolve_output opt
      @auth = resolve_auth opt
      @prompt = resolve_prompt opt
      @vars = opt[:vars]
      @stats = Stats.new
      @retry = 0
      @repo = resolve_repo opt

      # model instance needs to access node instance
      @model.node = self
    end

    def run
      status, config = :fail, nil
      @input.each do |input|
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

    def run_input(input)
      rescue_fail = {}
      [input.class::RescueFail, input.class.superclass::RescueFail].each do |hash|
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
        false
      rescue StandardError => err
        crashdir  = Oxidized.config.crash.directory
        crashfile = Oxidized.config.crash.hostnames? ? name : ip.to_s
        FileUtils.mkdir_p(crashdir) unless File.directory?(crashdir)

        File.open File.join(crashdir, crashfile), 'w' do |fh|
          fh.puts Time.now.utc
          fh.puts err.message + ' [' + err.class.to_s + ']'
          fh.puts '-' * 50
          fh.puts err.backtrace
        end
        Oxidized.logger.error '%s raised %s with msg "%s", %s saved' % [ip, err.class, err.message, crashfile]
        false
      end
    end

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

    def reset
      @user = @email = @msg = @from = nil
      @retry = 0
    end

    def modified
      @stats.update_mtime
    end

    private

    def resolve_prompt(opt)
      opt[:prompt] || @model.prompt || Oxidized.config.prompt
    end

    def resolve_auth(opt)
      # Resolve configured username/password
      {
        username: resolve_key(:username, opt),
        password: resolve_key(:password, opt)
      }
    end

    def resolve_input(opt)
      inputs = resolve_key :input, opt, Oxidized.config.input.default
      inputs.split(/\s*,\s*/).map do |input|
        Oxidized.mgr.add_input(input) || raise(MethodNotFound, "#{input} not found for node #{ip}") unless Oxidized.mgr.input[input]
        Oxidized.mgr.input[input]
      end
    end

    def resolve_output(opt)
      output = resolve_key :output, opt, Oxidized.config.output.default
      Oxidized.mgr.add_output(output) || raise(MethodNotFound, "#{output} not found for node #{ip}") unless Oxidized.mgr.output[output]
      Oxidized.mgr.output[output]
    end

    def resolve_model(opt)
      model = resolve_key :model, opt
      unless Oxidized.mgr.model[model]
        Oxidized.logger.debug "lib/oxidized/node.rb: Loading model #{model.inspect}"
        Oxidized.mgr.add_model(model) || raise(ModelNotFound, "#{model} not found for node #{ip}")
      end
      Oxidized.mgr.model[model].new
    end

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

    def resolve_key(key, opt, global = nil)
      # resolve key, first get global, then get group then get node config
      key_sym = key.to_sym
      key_str = key.to_s
      value   = global
      Oxidized.logger.debug "node.rb: resolving node key '#{key}', with passed global value of '#{value}' and node value '#{opt[key_sym]}'"

      # global
      if (not value) && Oxidized.config.has_key?(key_str)
        value = Oxidized.config[key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from global"
      end

      # group
      if Oxidized.config.groups.has_key?(@group)
        if Oxidized.config.groups[@group].has_key?(key_str)
          value = Oxidized.config.groups[@group][key_str]
          Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from group"
        end
      end

      # model
      if Oxidized.config.models.has_key?(@model.class.name.to_s.downcase)
        if Oxidized.config.models[@model.class.name.to_s.downcase].has_key?(key_str)
          value = Oxidized.config.models[@model.class.name.to_s.downcase][key_str]
          Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from model"
        end
      end

      # node
      value = opt[key_sym] || value
      Oxidized.logger.debug "node.rb: returning node key '#{key}' with value '#{value}'"
      value
    end

    def git_type(opt)
      type = opt[:output] || Oxidized.config.output.default
      return nil unless type[0..2] == "git"

      type
    end
  end
end
