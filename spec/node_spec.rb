require 'spec_helper'

describe Oxidized::Node do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               output:   'git',
                               model:    'junos',
                               username: 'alma',
                               password: 'armud',
                               prompt:   'test_prompt')
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

      status, = @node.run
      status.must_equal :success
    end
    it 'should record the success' do
      stub_oxidized_ssh

      before_successes = @node.stats.successes
      j = Oxidized::Job.new @node
      j.join
      @node.stats.add j
      after_successes = @node.stats.successes
      successes = after_successes - before_successes
      successes.must_equal 1
    end
    it 'should record a failure' do
      stub_oxidized_ssh_fail

      before_fails = @node.stats.failures
      j = Oxidized::Job.new @node
      j.join
      @node.stats.add j
      after_fails = @node.stats.failures
      fails = after_fails - before_fails
      fails.must_equal 1
    end
  end

  describe '#repo' do
    before do
      Oxidized.config.output.default = 'git'
      Oxidized::Node.any_instance.unstub(:resolve_repo)
    end

    let(:group) { nil }
    let(:node) do
      Oxidized::Node.new(
        ip: '127.0.0.1', group: group, model: 'junos'
      )
    end

    it 'when there are no groups' do
      Oxidized.config.output.git.repo = '/tmp/repository.git'
      node.repo.must_equal '/tmp/repository.git'
    end

    describe 'when there are groups' do
      let(:group) { 'ggrroouupp' }

      before do
        Oxidized.config.output.git.single_repo = single_repo
      end

      describe 'with only one repository' do
        let(:single_repo) { true }

        before do
          Oxidized.config.output.git.repo = '/tmp/repository.git'
        end

        it 'should use the correct remote' do
          node.repo.must_equal '/tmp/repository.git'
        end
      end

      describe 'with more than one repository' do
        let(:single_repo) { nil }

        before do
          Oxidized.config.output.git.repo.ggrroouupp = '/tmp/ggrroouupp.git'
        end

        it 'should use the correct remote' do
          node.repo.must_equal '/tmp/ggrroouupp.git'
        end
      end
    end
  end
end
