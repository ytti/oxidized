require_relative 'model_helper'

# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case

class ATOMS
  DIRECTORY = 'spec/model/data'.freeze
  def self.tests_get
    tests = {
      output: [],
      prompt: []
    }

    Dir[File.join(DIRECTORY, '*:output.txt')].each do |file|
      model, desc, _type = *File.basename(file, '.txt').split(':')
      tests[:output] << TestOutput.new(model, desc)
    end

    Dir[File.join(DIRECTORY, '*:prompt.yaml')].each do |file|
      model, desc, _type = *File.basename(file, '.yaml').split(':')
      tests[:prompt] << TestPrompt.new(model, desc)
    end

    tests
  end

  class Test
    attr_reader :model, :desc

    def initialize(model, desc)
      @model = model
      @desc = desc
      @skip = false
    end

    def skip?
      @skip
    end

    def get_filename(type)
      ext = type == 'output' ? '.txt' : '.yaml'
      [@model, @desc, type].join(':') + ext
    end

    def load_file(file_name)
      ext = File.extname(file_name)
      if ext == '.yaml'
        YAML.load_file(File.join(DIRECTORY, file_name))
      else
        File.read(File.join(DIRECTORY, file_name))
      end
    rescue StandardError
      nil
    end
  end

  class TestOutput < Test
    attr_reader :simulation, :output

    def initialize(model, desc)
      super

      @simulation = load_file(get_filename('simulation'))
      @output = load_file(get_filename('output'))
      @skip = true unless @simulation && @output
    end
  end

  class TestPrompt < Test
    attr_reader :data

    def initialize(model, desc)
      super

      @data = load_file(get_filename('prompt'))
      @skip = true unless @data
    end
  end
end

describe 'ATOMS tests' do
  tests = ATOMS.tests_get

  tests[:output].each do |test|
    next if test.skip?

    before(:each) do
      init_model_helper
    end

    it "ATOMS ('#{test.model}' / '#{test.desc}') has expected output" do
      @node = Oxidized::Node.new(name:  'example.com',
                                 input: 'ssh',
                                 model: test.model)
      mockmodel = MockSsh2.new(test)
      Net::SSH.stubs(:start).returns mockmodel
      status, result = @node.run
      _(status).must_equal :success
      _(result.to_cfg).must_equal mockmodel.oxidized_output
    end
  end

  tests[:prompt].each do |test|
    next if test.skip?

    it "ATOMS ('#{test.model}' / '#{test.desc}') has working prompt detection" do
      prompt_re = Object.const_get(test.model.upcase).prompt
      test.data['pass']&.each do |want_pass|
        _(want_pass).must_match prompt_re
      end
      test.data['fail']&.each do |want_fail|
        _(want_fail).wont_match prompt_re
      end
    end
  end
end
