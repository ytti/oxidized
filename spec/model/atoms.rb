# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case
class ATOMS
  DIRECTORY = File.join(File.dirname(__FILE__), 'data').freeze
  class ATOMSError < StandardError; end

  # Returns a list of all tests matching the data files under ATOMS::DIRECTORY
  def self.all
    # enumerates through the subclasses of Test (TestPrompt, TestOutput...)
    [Test, TestPassFail].map(&:subclasses).flatten.map do |test|
      get(test, test::GLOB) if test::GLOB
    end.flatten.compact
  end

  # Returns an Array of ATOMS::Test instances of the subclass @klass matching
  # the data files with a pattern @glob in ATOMS::DIRECTORY
  #
  # @klass is a subclass of ATOMS::Test (TestPrompt, TestOutput...)
  # @glob is the pattern matching the test data.
  #
  # When called by ATOMS::all, @glob is @klass::GLOB
  # When called by atoms_genrate.rb, @globs matches '*:simulation.yaml'
  def self.get(klass, glob)
    Dir[File.join(DIRECTORY, glob)].map do |file|
      ext = File.extname(glob)
      # 'model:desc:type.txt' => test.new('model', 'desc', 'type')
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

  # Support class for loading the YAML simulation file and the expected output
  # file for a model unit test.
  #
  # The files are stored under ATOMS::DIRECTORY (spec/model/data) and follow the
  # naming convention:
  # - YAML Simulation: model:description:simulation.yaml
  # - Expected Output: model:description:output.txt
  #
  # "description" is the name of the test case and is generally formatted as
  # #hardware_#software or #model_#hardware_#software_#description.
  #
  # The test is skipped if one of the files is missing.
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

  # Support class for loading prompts to test as part of the model unit tests.
  #
  # The prompts are loaded from files stored under
  # ATOMS::DIRECTORY (spec/model/data) and follow the naming convention:
  # - model:description:prompt.yaml
  #
  # "description" is generally named 'generic', as all prompts for a model
  # can be stored into as single YAML file.
  #
  # The test is skipped if the YAML file could not be loaded.
  class TestPassFail < Test
    GLOB = false # this is not an actual test, but a parent for prompt/secret
    attr_reader :data

    def initialize(model, desc, type)
      super

      @data = load_file(type)
      @skip = true unless @data
    end

    def pass
      @data['pass'] or []
    end

    def fail
      @data['fail'] or []
    end
  end

  class TestPrompt < TestPassFail
    GLOB = '*:prompt.yaml'.freeze
    def initialize(model, desc, type = 'prompt')
      super
    end

    # Returns all prompts which should pass after Model::expects has been run
    # on them
    def pass_with_expect
      @data['pass_with_expect'] or []
    end
  end

  class TestSecret < TestPassFail
    GLOB = '*:secret.yaml'.freeze
    attr_reader :output_test

    def initialize(model, desc, type = 'secret')
      super

      @output_test = TestOutput.new(@model, @desc, 'output')
      @skip = true if @output_test.skip?
    end
  end
end
