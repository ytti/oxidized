require_relative 'model_helper'

# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case

class ATOMS
  DIRECTORY = 'spec/model/data'.freeze
  def tests_get
    tests = {
      output: [],
      prompt: []
    }

    Dir[File.join(DIRECTORY, '*:output.txt')].each do |file|
      model, desc, _type = *File.basename(file, '.txt').split(':')
      tests[:output] << TestOutput.new(model, desc)
    end

    Dir[File.join(DIRECTORY, '*:prompt.txt')].each do |file|
      model, desc, _type = *File.basename(file, '.txt').split(':')
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
  end

  class TestOutput < Test
    attr_reader :simulation, :output

    def initialize(model, desc)
      super

      simulation_file = [model, desc, 'simulation'].join(':') + '.yaml'
      output_file = [model, desc, 'output'].join(':') + '.txt'

      @simulation = YAML.load_file(File.join(DIRECTORY, simulation_file)) rescue nil
      @output = File.read(File.join(DIRECTORY, output_file)) rescue nil

      @skip = true unless @simulation && @output
    end
  end

  class TestPrompt < Test
    attr_reader :data

    def initialize(model, desc)
      super

      data_file = [model, desc, 'prompt'].join(':') + '.yaml'
      @data = YAML.load_file(File.join(DIRECTORY, data_file)) rescue nil

      @skip = true unless @data
    end
  end
end

describe 'ATOMS tests' do
  atoms = ATOMS.new
  tests = atoms.tests_get

  tests[:output].each do |test|
    next if test.skip?

    it "ATOMS ('#{test.model}' / '#{test.desc}') has expected output" do
      init_model_helper
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

    prompt_re = Object.const_get(test.model.upcase).prompt
    it "ATOMS ('#{test.model}' / '#{test.desc}') has working prompt detection" do
      test.data['pass']&.each do |want_pass|
        _(want_pass).must_match prompt_re
      end
      test.data['fail']&.each do |want_fail|
        _(want_fail).wont_match prompt_re
      end
    end
  end
end
