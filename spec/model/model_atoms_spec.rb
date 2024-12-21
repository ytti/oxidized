require_relative 'model_helper'

# Automatic Trivial Oxidized Model Spec - ATOMS
# Tries to simplify model testing for the simple/common case

class ATOMS
  DIRECTORY = 'spec/model/data'.freeze
  def self.tests_get
    tests = []

    Dir[File.join(DIRECTORY, '*:output.txt')].each do |file|
      model, desc, type = *File.basename(file, '.txt').split(':')
      tests << TestOutput.new(model, desc, type)
    end

    Dir[File.join(DIRECTORY, '*:prompt.yaml')].each do |file|
      model, desc, type = *File.basename(file, '.yaml').split(':')
      tests << TestPrompt.new(model, desc, type)
    end

    tests
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

    def get_filename(type)
      ext = type == 'output' ? '.txt' : '.yaml'
      [@model, @desc, type].join(':') + ext
    end

    def load_file(type = nil)
      file_name = get_filename((type or @type))
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

    def initialize(model, desc, type)
      super

      @simulation = load_file('simulation')
      @output = load_file
      @skip = true unless @simulation && @output
    end
  end

  class TestPrompt < Test
    attr_reader :data

    def initialize(model, desc, type)
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

describe 'ATOMS tests' do
  ATOMS.tests_get.each do |test|
    test_string = "ATOMS/#{test.type} (#{test.model} / #{test.desc})"

    before(:each) do
      init_model_helper
      @node = Oxidized::Node.new(name:  'example.com',
                                 input: 'ssh',
                                 model: test.model)
    end

    if test.type == 'output'
      it "#{test_string} has expected output" do
        skip("check simulation+output data file for #{test_string}") if test.skip?
        mockmodel = MockSsh2.new(test)
        Net::SSH.stubs(:start).returns mockmodel
        status, result = @node.run
        _(status).must_equal :success
        _(result.to_cfg).must_equal mockmodel.oxidized_output
      end

    elsif test.type == 'prompt'
      it "#{test_string} has working prompt detection" do
        skip("check prompt data file for #{test_string}") if test.skip?
        prompt_re = Object.const_get(test.model.upcase).prompt
        test.pass.each do |want_pass|
          _(want_pass).must_match prompt_re
        end
        test.fail.each do |want_fail|
          _(want_fail).wont_match prompt_re
        end
      end
    end
  end
end
