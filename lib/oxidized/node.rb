module Oxidized
  require 'resolv'
  require_relative 'node/stats'
  class MethodNotFound < OxidizedError; end
  class ModelNotFound  < OxidizedError; end
  class Node
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt, :vars, :last, :error
    attr_accessor :running, :user, :msg, :from, :stats
    alias :running? :running
    def initialize opt
      @name           = opt[:name]
      @ip             = Resolv.getaddress @name
      @group          = opt[:group]
      @input          = resolve_input opt
      @output         = resolve_output opt
      @model          = resolve_model opt
      @auth           = resolve_auth opt
      @prompt         = resolve_prompt opt
      @vars           = opt[:vars]
      @stats          = Stats.new

      # model instance needs to access node instance
      @model.node = self
    end

    def run
      status, config, @error = :fail, nil, nil
      @input.each do |input|
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
        if input.connect self
          input.get
        end
      rescue *rescue_fail.keys => err
        @error = err
        resc  = ''
        if not level = rescue_fail[err.class]
          resc  = err.class.ancestors.find{|e|rescue_fail.keys.include? e}
          level = rescue_fail[resc]
          resc  = " (rescued #{resc})"
        end
        Log.send(level, '%s raised %s%s with msg "%s"' % [self.ip, err.class, resc, err.message])
        return false
      rescue => err
        @error = err
        file = Oxidized::Config::Crash + '.' + self.ip.to_s
        open file, 'w' do |fh|
          fh.puts Time.now.utc
          fh.puts err.message + ' [' + err.class.to_s + ']'
          fh.puts '-' * 50
          fh.puts err.backtrace
        end
        Log.error '%s raised %s with msg "%s", %s saved' % [self.ip, err.class, err.message, file]
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
      ostruct = OpenStruct.new
      ostruct.start  = job.start
      ostruct.end    = job.end
      ostruct.status = job.status
      ostruct.time   = job.time
      @last = ostruct
    end

    def reset
      @user = @msg = @from = nil
    end

    private

    def resolve_prompt opt
      prompt =   opt[:prompt]
      prompt ||= @model.prompt
      prompt ||= CFG.prompt
    end

    def resolve_auth opt
      # Resolve configured username/password, give priority to group level configuration
      # TODO: refactor to use revised behaviour of Asetus
      cfg_username, cfg_password =
        if CFG.groups.has_key?(@group) and ['username', 'password'].all? {|e| CFG.groups[@group].has_key?(e)}
          [CFG.groups[@group].username, CFG.groups[@group].password]
        elsif ['username', 'password'].all? {|e| CFG.has_key?(e)}
          [CFG.username, CFG.password]
        else
          [nil, nil]
        end
      auth = {}
      auth[:username] = (opt[:username] or cfg_username)
      auth[:password] = (opt[:password] or cfg_password)
      auth
    end

    def resolve_input opt
      inputs = (opt[:input]  or CFG.input.default)
      inputs.split(/\s*,\s*/).map do |input|
        if not Oxidized.mgr.input[input]
          Oxidized.mgr.add_input input or raise MethodNotFound, "#{input} not found for node #{ip}"
        end
        Oxidized.mgr.input[input]
      end
    end

    def resolve_output opt
      output = (opt[:output] or CFG.output.default)
      if not Oxidized.mgr.output[output]
        Oxidized.mgr.add_output output or raise MethodNotFound, "#{output} not found for node #{ip}"
      end
      Oxidized.mgr.output[output]
    end

    def resolve_model opt
      model = (opt[:model] or CFG.model)
      if not Oxidized.mgr.model[model]
        Oxidized.mgr.add_model model or raise ModelNotFound, "#{model} not found for node #{ip}"
      end
      Oxidized.mgr.model[model].new
    end

  end
end
