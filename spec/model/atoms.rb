# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case

class ATOMS
  DIRECTORY = 'spec/model/data'.freeze

  def self.get
    Test.subclasses.map do |test|
      Dir[File.join(DIRECTORY, test::GLOB)].map do |file|
        ext = File.extname(test::GLOB)
        test.new(*File.basename(file, ext).split(':'))
      end
    end.flatten
  end

  class Test
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
      to_s(type) + ext
    end

    def load_file(type = nil)
      file_name = get_filename((type or @type))
      file_name = File.join(DIRECTORY, file_name)
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
    attr_reader :simulation, :output

    def initialize(model, desc, type = 'output')
      super

      @simulation = load_file('simulation')
      @output = load_file
      @skip = true unless @simulation && @output
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
