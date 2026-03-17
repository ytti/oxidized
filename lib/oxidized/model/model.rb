require 'strscan'
require_relative 'outputs'
require_relative 'dslsetup'
require_relative 'dslcommands'

module Oxidized
  class Model
    include SemanticLogger::Loggable

    using Refinements

    # Domain Specific Language for models
    extend Oxidized::Model::DSLSetup
    extend Oxidized::Model::DSLCommands

    include Oxidized::Config::Vars

    # rubocop:disable Style/FormatStringToken
    METADATA_DEFAULT = "%{comment}Fetched by Oxidized with model %{model} " \
                       "from host %{name} [%{ip}]\n".freeze
    # rubocop:enable Style/FormatStringToken

    class << self
      def inherited(klass)
        super
        if klass.superclass == Oxidized::Model
          klass.instance_variable_set('@cmd',     Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set('@cfg',     Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set('@procs',   Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set '@expect',  []
          klass.instance_variable_set '@comment', nil
          klass.instance_variable_set '@prompt',  nil
          klass.instance_variable_set '@metadata', {}
          klass.instance_variable_set '@inputs', nil

        else # we're subclassing some existing model, take its variables
          instance_variables.each do |var|
            iv = instance_variable_get(var)
            klass.instance_variable_set var, iv.dup
            @cmd[:cmd] = iv[:cmd].dup if var.to_s == "@cmd"
          end
        end
      end
    end

    attr_accessor :input, :node

    # input specifies to run this command only with this input type
    # if input is not specified, always run the command
    def cmd(string, input: nil, &block)
      logger.debug "Executing #{string}"
      out = if input.nil? || input.include?(@input.to_sym)
              out = @input.cmd(string)
            else
              # Do not run this command
              return ''
            end
      return false unless out

      out = out.b unless Oxidized.config.input.utf8_encoded?
      self.class.cmds[:all].each do |all_block|
        out = instance_exec out, string, &all_block
      end
      if vars :remove_secret
        self.class.cmds[:secret].each do |all_block|
          out = instance_exec out, string, &all_block
        end
      end
      out = instance_exec out, &block if block
      process_cmd_output out, string
    end

    def metadata(position)
      return unless %i[top bottom].include? position

      model_metadata = self.class.instance_variable_get(:@metadata)
      var_position = { top: "metadata_top", bottom: "metadata_bottom" }
      if model_metadata[:top] || model_metadata[:bottom]
        # the model defines metadata at :top ot :bottom, use the model
        value = model_metadata[position]
        value.is_a?(Proc) ? instance_eval(&value) : interpolate_string(value)
      elsif vars("metadata_top") || vars("metadata_bottom")
        # vars defines metadata_top or metadata bottom, use the vars
        interpolate_string(vars(var_position[position]))
      elsif position == :top
        # default: use METADATA_DEFAULT for top
        interpolate_string(METADATA_DEFAULT)
      end
    end

    def interpolate_string(template)
      return nil unless template

      time = Time.now
      template_variables = {
        model:   self.class.name,
        name:    node.name,
        ip:      node.ip,
        group:   node.group,
        comment: self.class.comment,
        year:    time.year,
        month:   "%02d" % time.month,
        day:     "%02d" % time.day,
        hour:    "%02d" % time.hour,
        minute:  "%02d" % time.min,
        second:  "%02d" % time.sec
      }
      template % template_variables
    end

    def output
      @input.output
    end

    def send(data)
      @input.send data
    end

    def expect(...)
      self.class.expect(...)
    end

    def cfg
      self.class.cfgs
    end

    def prompt
      self.class.prompt
    end

    def expects(data)
      self.class.expects.each do |re, cb|
        if data.match re
          data = cb.arity == 2 ? instance_exec([data, re], &cb) : instance_exec(data, &cb)
        end
      end
      data
    end

    # Get the commands from the model
    def get
      logger.debug 'Collecting commands\' outputs'
      outputs = Outputs.new
      self.class.cmds[:cmd].each do |data|
        command = data[:cmd]
        args = data[:args]
        block = data[:block]

        next if args.include?(:if) && !instance_exec(&args[:if])

        out = cmd command, input: args[:input], &block
        return false unless out

        outputs << out
      end
      procs = self.class.procs
      procs[:pre].each do |pre_proc|
        outputs.unshift process_cmd_output(instance_eval(&pre_proc), '')
      end
      procs[:post].each do |post_proc|
        outputs << process_cmd_output(instance_eval(&post_proc), '')
      end
      if vars("metadata") == true
        metadata_top = metadata(:top)
        metadata_bottom = metadata(:bottom)
        outputs.unshift metadata_top if metadata_top
        outputs << metadata_bottom if metadata_bottom
      end
      outputs
    end

    def comment(str)
      data = String.new('')
      str.each_line do |line|
        data << self.class.comment << line
      end
      data
    end

    def xmlcomment(str)
      # XML Comments start with <!-- and end with -->
      #
      # Because it's illegal for the first or last characters of a comment
      # to be a -, i.e. <!--- or ---> are illegal, and also to improve
      # readability, we add extra spaces after and before the beginning
      # and end of comment markers.
      #
      # Also, XML Comments must not contain --. So we put a space between
      # any double hyphens, by replacing any - that is followed by another -
      # with '- '
      data = String.new('')
      str.each_line do |_line|
        data << '<!-- ' << str.gsub(/-(?=-)/, '- ').chomp << " -->\n"
      end
      data
    end

    def screenscrape
      @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
    end

    def significant_changes(config)
      self.class.cmds[:significant_changes].each do |block|
        config = instance_exec config, &block
      end
      config
    end

    private

    def process_cmd_output(output, name)
      output = String.new('') unless output.instance_of?(String)
      output.process_cmd(name)
      output
    end
  end
end
