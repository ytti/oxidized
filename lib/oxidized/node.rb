module Oxidized
  require 'resolv'
  class MethodNotFound < StandardError; end
  class ModelNotFound < StandardError; end
  class Node
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt
    attr_accessor :last, :running, :user, :msg, :from
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
    end

    def run
      status, config = :fail, nil
      @input.each do |input|
        @model.input = input = input.new
        if config=run_input(input)
          status = :success
          break
        else
          status = :no_connection
        end
      end
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
      rescue *rescue_fail.keys.flatten => err
        level = rescue_fail[err.class]
        Log.send(level, '%s raised %s with msg "%s"' % [self.ip, err.class, err.message])
        return false
      end
    end

    def serialize
      h = {
        :name  => @name,
        :ip    => @ip,
        :group => @group,
        :model => @model.class.to_s,
        :last  => nil,
      }
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
      auth = {}
      auth[:username] = (opt[:username] or CFG.username)
      auth[:password] = (opt[:passowrd] or CFG.password)
      auth
    end

    def resolve_input opt
      inputs = (opt[:input]  or CFG.input[:default])
      inputs.split(/\s*,\s*/).map do |input|
        if not Oxidized.mgr.input[input]
          Oxidized.mgr.input = input or raise MethodNotFound, "#{input} not found"
        end
        Oxidized.mgr.input[input]
      end
    end

    def resolve_output opt
      output = (opt[:output] or CFG.output[:default])
      if not Oxidized.mgr.output[output]
        Oxidized.mgr.output = output or raise MethodNotFound, "#{output} not found"
      end
      Oxidized.mgr.output[output]
    end

    def resolve_model opt
      model = (opt[:model] or CFG.model)
      mgr = Oxidized.mgr
      if not mgr.model[model]
        mgr.model = model or raise ModelNotFound, "#{model} not found"
      end
      mgr.model[model].new
    end

  end
end
