# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case
class ATOMS
  DIRECTORY = File.join(File.dirname(__FILE__), 'data').freeze
  class ATOMSError < StandardError; end

  def self.all
    Test.subclasses.map do |test|
      get(test, test::GLOB)
    end.flatten
  end

  def self.get(klass, glob)
    Dir[File.join(DIRECTORY, glob)].map do |file|
      ext = File.extname(glob)
      klass.new(*File.basename(file, ext).split(':'))
    end
  end

  class Test
    class TestError < ATOMSError; end
    attr_reader :model, :desc, :type

    def initialize(model, desc, type)
      @model = model
      @desc = desc
      @type = type
      @skip = false
    end

    def skip?
      @skip
    end

    def to_s(type = @type)
      [@model, @desc, type].join(':')
    end

    def get_filename(type)
      ext = type == 'output' ? '.txt' : '.yaml'
      File.join(DIRECTORY, to_s(type) + ext)
    end

    def load_file(type = nil)
      file_name = get_filename((type or @type))
      if File.extname(file_name) == '.yaml'
        YAML.load_file(file_name)
      else
        File.read(file_name)
      end
    rescue StandardError
      nil
    end
  end

  class TestOutput < Test
    GLOB = '*:output.txt'.freeze
    class TestOutputError < TestError; end
    class OutputGenerationError < TestOutputError; end
    attr_reader :simulation, :output

    def initialize(model, desc, type = 'output')
      super

      @simulation = load_file('simulation')
      @output = load_file('output')
      @skip = true unless @simulation && @output
    end

    def generate(result_engine)
      raise OutputGenerationError, 'FAIL, no simulation file' unless @simulation
      raise OutputGenerationError, 'SKIP, output already exists' if @output

      File.write(get_filename('output'), result_engine.get_result(nil, self).to_cfg)
    end
  end

  class TestPrompt < Test
    GLOB = '*:prompt.yaml'.freeze
    attr_reader :data

    def initialize(model, desc, type = 'prompt')
      super

      @data = load_file
      @skip = true unless @data
    end

    def pass
      @data['pass'] or []
    end

    def fail
      @data['fail'] or []
    end
  end
end
