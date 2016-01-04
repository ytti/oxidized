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
      if Oxidized.config.debug == true or opt[:debug] == true
        puts 'resolving DNS for %s...' % opt[:name]
      end
      @name           = opt[:name]
      @ip             = IPAddr.new(opt[:ip]).to_s rescue nil
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
      @repo           = Oxidized.config.output.git.repo

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
          status = :success
          break
        else
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
      # Resolve configured username/password, give priority to group level configuration
      # TODO: refactor to use revised behaviour of Asetus
      cfg_username, cfg_password =
        if Oxidized.config.groups.has_key?(@group) and ['username', 'password'].all? {|e| Oxidized.config.groups[@group].has_key?(e)}
          [Oxidized.config.groups[@group].username, Oxidized.config.groups[@group].password]
        elsif ['username', 'password'].all? {|e| Oxidized.config.has_key?(e)}
          [Oxidized.config.username, Oxidized.config.password]
        else
          [nil, nil]
        end
      auth = {}
      auth[:username] = (opt[:username] or cfg_username)
      auth[:password] = (opt[:password] or cfg_password)
      auth
    end

    def resolve_input opt
      inputs = (opt[:input]  or Oxidized.config.input.default)
      inputs.split(/\s*,\s*/).map do |input|
        if not Oxidized.mgr.input[input]
          Oxidized.mgr.add_input input or raise MethodNotFound, "#{input} not found for node #{ip}"
        end
        Oxidized.mgr.input[input]
      end
    end

    def resolve_output opt
      output = (opt[:output] or Oxidized.config.output.default)
      if not Oxidized.mgr.output[output]
        Oxidized.mgr.add_output output or raise MethodNotFound, "#{output} not found for node #{ip}"
      end
      Oxidized.mgr.output[output]
    end

    def resolve_model opt
      model = (opt[:model] or Oxidized.config.model)
      if not Oxidized.mgr.model[model]
        Oxidized.mgr.add_model model or raise ModelNotFound, "#{model} not found for node #{ip}"
      end
      Oxidized.mgr.model[model].new
    end

  end
end
