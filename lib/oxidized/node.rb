module Oxidized
  require 'resolv'
  class MethodNotFound < StandardError; end
  class ModelNotFound < StandardError; end
  class Node
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt
    attr_accessor :last, :running
    alias :running? :running
    def initialize opt
      @name           = opt[:name]
      @ip             = Resolv.getaddress @name
      @group          = opt[:group]
      @input, @output = resolve_io opt
      @model          = resolve_model opt
      @auth           = resolve_auth opt
      @prompt         = resolve_prompt opt
    end

    def run
      status, config = :fail, nil
      @model.input = input = @input.new
      if input.connect self
        config = input.get
        status = :success if config
      else
        status = :no_cconnection
      end
      [status, config]
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

    def resolve_io opt
      input  = (opt[:input]  or CFG.input[:default])
      output = (opt[:output] or CFG.output[:default])
      mgr = Oxidized.mgr
      if not mgr.input[input]
        mgr.input = input or raise MethodNotFound, "#{input} not found"
      end
      if not mgr.output[output]
        mgr.output = output or raise MethodNotFound, "#{output} not found"
      end
      [ mgr.input[input], mgr.output[output] ]
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
