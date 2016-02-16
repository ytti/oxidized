require 'spec_helper'

describe Oxidized::Node do
  before(:each) do
    Oxidized.stubs(:asetus).returns(Asetus.new)
    Oxidized.config.output.git.repo = '/tmp/repository.git'

    Oxidized::Node.any_instance.stubs(:resolve_output)
    @node = Oxidized::Node.new(name: 'example.com',
                               input: 'ssh',
                               output: 'git',
                               model: 'junos',
                               username: 'alma',
                               password: 'armud',
                               prompt: 'test_prompt')

  end

  describe '#new' do
    it 'should resolve input' do
      @node.input[0].to_s.split('::')[1].must_equal 'SSH'
    end
    it 'should resolve model' do
      @node.model.class.must_equal JunOS
    end
    it 'should resolve username' do
      @node.auth[:username].must_equal 'alma'
    end
    it 'should resolve password' do
      @node.auth[:password].must_equal 'armud'
    end
    it 'should require prompt' do
      @node.prompt.must_equal 'test_prompt'
    end
  end

  describe '#run' do
    it 'should fetch the configuration' do
      stub_oxidized_ssh

      status, _ = @node.run
      status.must_equal :success
    end
  end

  describe '#repo' do
    it 'when there is no groups' do
      @node.repo.must_equal '/tmp/repository.git'
    end

    describe 'when there are groups' do
      let(:node) do
        Oxidized::Node.new({
          ip: '127.0.0.1', group: 'ggrroouupp', model: 'junos'
        })
      end

      it 'with only one repository' do
        Oxidized.config.output.git.single_repo = true
        node.repo.must_equal '/tmp/repository.git'
      end

      it 'with more than one repository' do
        Oxidized.config.output.git.single_repo = false
        node.repo.must_equal '/tmp/ggrroouupp.git'
      end
    end
  end
end
