module Oxidized
  require 'resolv'
  require 'ostruct'
  require_relative 'node/stats'
  class MethodNotFound < OxidizedError; end
  class ModelNotFound  < OxidizedError; end
  class Node
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt, :vars, :last, :repo
    attr_accessor :running, :user, :msg, :from, :stats, :retry
    alias :running? :running
    def initialize opt
      Oxidized.logger.debug 'resolving DNS for %s...' % opt[:name]
      # remove the prefix if an IP Address is provided with one as IPAddr converts it to a network address.
      ip_addr, _ = opt[:ip].to_s.split("/")
      Oxidized.logger.debug 'IPADDR %s' % ip_addr.to_s
      @name           = opt[:name]
      @ip             = IPAddr.new(ip_addr).to_s rescue nil
      @ip           ||= Resolv.new.getaddress @name
      @group          = opt[:group]
      @input          = resolve_input opt
      @output         = resolve_output opt
      @model          = resolve_model opt
      @auth           = resolve_auth opt
      @prompt         = resolve_prompt opt
      @vars           = opt[:vars]
      @stats          = Stats.new
      @retry          = 0
      @repo           = resolve_repo opt

      # model instance needs to access node instance
      @model.node = self
    end

    def run
      status, config = :fail, nil
      @input.each do |input|
        # don't try input if model is missing config block, we may need strong config to class_name map
        cfg_name = input.to_s.split('::').last.downcase
        next unless @model.cfg[cfg_name] and not @model.cfg[cfg_name].empty?
        @model.input = input = input.new
        if config=run_input(input)
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

    def run_input input
      rescue_fail = {}
      [input.class::RescueFail, input.class.superclass::RescueFail].each do |hash|
        hash.each do |level,errors|
          errors.each do |err|
            rescue_fail[err] = level
          end
        end
      end
      begin
        input.connect(self) and input.get
      rescue *rescue_fail.keys => err
        resc  = ''
        if not level = rescue_fail[err.class]
          resc  = err.class.ancestors.find{|e|rescue_fail.keys.include? e}
          level = rescue_fail[resc]
          resc  = " (rescued #{resc})"
        end
        Oxidized.logger.send(level, '%s raised %s%s with msg "%s"' % [self.ip, err.class, resc, err.message])
        return false
      rescue => err
        file = Oxidized::Config::Crash + '.' + self.ip.to_s
        open file, 'w' do |fh|
          fh.puts Time.now.utc
          fh.puts err.message + ' [' + err.class.to_s + ']'
          fh.puts '-' * 50
          fh.puts err.backtrace
        end
        Oxidized.logger.error '%s raised %s with msg "%s", %s saved' % [self.ip, err.class, err.message, file]
        return false
      end
    end

    def serialize
      h = {
        :name      => @name,
        :full_name => @name,
        :ip        => @ip,
        :group     => @group,
        :model     => @model.class.to_s,
        :last      => nil,
        :vars      => @vars,
      }
      h[:full_name] = [@group, @name].join('/') if @group
      if @last
        h[:last] = {
          :start  => @last.start,
          :end    => @last.end,
          :status => @last.status,
          :time   => @last.time,
        }
      end
      h
    end

    def last= job
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
      @user = @msg = @from = nil
      @retry = 0
    end

    private

    def resolve_prompt opt
      opt[:prompt] || @model.prompt || Oxidized.config.prompt
    end

    def resolve_auth opt
      # Resolve configured username/password
      {
        username:       resolve_key(:username, opt),
        password:       resolve_key(:password, opt),
      }
    end

    def resolve_input opt
      inputs = resolve_key :input, opt, Oxidized.config.input.default
      inputs.split(/\s*,\s*/).map do |input|
        if not Oxidized.mgr.input[input]
          Oxidized.mgr.add_input input or raise MethodNotFound, "#{input} not found for node #{ip}"
        end
        Oxidized.mgr.input[input]
      end
    end

    def resolve_output opt
      output = resolve_key :output, opt, Oxidized.config.output.default
      if not Oxidized.mgr.output[output]
        Oxidized.mgr.add_output output or raise MethodNotFound, "#{output} not found for node #{ip}"
      end
      Oxidized.mgr.output[output]
    end

    def resolve_model opt
      model = resolve_key :model, opt
      if not Oxidized.mgr.model[model]
        Oxidized.logger.debug "lib/oxidized/node.rb: Loading model #{model.inspect}"
        Oxidized.mgr.add_model model or raise ModelNotFound, "#{model} not found for node #{ip}"
      end
      Oxidized.mgr.model[model].new
    end

    def resolve_repo opt
      if is_git? opt
        remote_repo = Oxidized.config.output.git.repo

        if remote_repo.is_a?(::String)
          if Oxidized.config.output.git.single_repo? || @group.nil?
            remote_repo
          else
            File.join(File.dirname(remote_repo), @group + '.git')
          end
        else
          remote_repo[@group]
        end
      elsif is_gitcrypt? opt
        remote_repo = Oxidized.config.output.gitcrypt.repo

        if remote_repo.is_a?(::String)
          if Oxidized.config.output.gitcrypt.single_repo? || @group.nil?
            remote_repo
          else
            File.join(File.dirname(remote_repo), @group + '.git')
          end
        else
          remote_repo[@group]
        end
      else
        return
      end
    end

    def resolve_key key, opt, global=nil
      # resolve key, first get global, then get group then get node config
      key_sym = key.to_sym
      key_str = key.to_s
      value   = global
      Oxidized.logger.debug "node.rb: resolving node key '#{key}', with passed global value of '#{value}' and node value '#{opt[key_sym]}'"

      #global
      if not value and Oxidized.config.has_key?(key_str)
        value = Oxidized.config[key_str]
        Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from global"
      end

      #group
      if Oxidized.config.groups.has_key?(@group)
        if Oxidized.config.groups[@group].has_key?(key_str)
          value = Oxidized.config.groups[@group][key_str]
          Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from group"
        end
      end

      #model
      if Oxidized.config.models.has_key?(@model.class.name.to_s.downcase)
        if Oxidized.config.models[@model.class.name.to_s.downcase].has_key?(key_str)
          value = Oxidized.config.models[@model.class.name.to_s.downcase][key_str]
          Oxidized.logger.debug "node.rb: setting node key '#{key}' to value '#{value}' from model"
        end
      end

      #node
      value = opt[key_sym] || value
      Oxidized.logger.debug "node.rb: returning node key '#{key}' with value '#{value}'"
      value
    end

    def is_git? opt
      (opt[:output] || Oxidized.config.output.default) == 'git'
    end

    def is_gitcrypt? opt
      (opt[:output] || Oxidized.config.output.default) == 'gitcrypt'
    end

  end
end
