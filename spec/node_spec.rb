require_relative 'spec_helper'

describe Oxidized::Node do
  before(:each) do
    Oxidized.asetus = Asetus.new

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
      _(@node.input[0].to_s.split('::')[1]).must_equal 'SSH'
    end
    it 'should resolve model' do
      _(@node.model.class).must_equal JunOS
    end
    it 'should resolve username' do
      _(@node.auth[:username]).must_equal 'alma'
    end
    it 'should resolve password' do
      _(@node.auth[:password]).must_equal 'armud'
    end
    it 'should require prompt' do
      _(@node.prompt).must_equal 'test_prompt'
    end
  end

  describe '#run' do
    it 'should fetch the configuration' do
      stub_oxidized_ssh

      status, = @node.run
      _(status).must_equal :success
    end
    it 'should record the success' do
      stub_oxidized_ssh

      before_successes = @node.stats.successes
      j = Oxidized::Job.new @node
      j.join
      @node.stats.add j
      after_successes = @node.stats.successes
      successes = after_successes - before_successes
      _(successes).must_equal 1
    end
    it 'should record a failure' do
      stub_oxidized_ssh_fail

      before_fails = @node.stats.failures
      j = Oxidized::Job.new @node
      j.join
      @node.stats.add j
      after_fails = @node.stats.failures
      fails = after_fails - before_fails
      _(fails).must_equal 1
    end

    it 'should warn when no suitable input has been found' do
      node = Oxidized::Node.new(name:     'example.com',
                                input:    'http',
                                output:   'git',
                                model:    'junos',
                                username: 'alma',
                                password: 'armud',
                                prompt:   'test_prompt')
      Oxidized::Node.logger.expects(:error)
                    .with("No suitable input found for example.com")
      status, = node.run
      _(status).must_equal :fail
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
      _(node.repo).must_equal '/tmp/repository.git'
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
          _(node.repo).must_equal '/tmp/repository.git'
        end
      end

      describe 'with more than one repository' do
        let(:single_repo) { nil }

        before do
          Oxidized.config.output.git.repo.ggrroouupp = '/tmp/ggrroouupp.git'
        end

        it 'should use the correct remote' do
          _(node.repo).must_equal '/tmp/ggrroouupp.git'
        end
      end
    end
  end

  describe '#resolve_key test hierarchy' do
    let(:group) { 'test_group' }
    let(:model) { 'junos' }
    let(:node) do
      Oxidized::Node.new(
        ip: '127.0.0.1', group: group, model: model
      )
    end

    describe 'create node with different usernames defined on each level' do
      it 'should use global username if set' do
        Oxidized.config.username = "global_username"
        _(node.auth[:username]).must_equal "global_username"
      end
      it 'should prefer model username over global one' do
        Oxidized.config.username = "global_username"
        Oxidized.config.models[model].username = "model_username"
        _(node.auth[:username]).must_equal "model_username"
      end
      it 'should prefer group username over model one' do
        Oxidized.config.username = "global_username"
        Oxidized.config.models[model].username = "model_username"
        Oxidized.config.groups[group].username = "group_username"
        _(node.auth[:username]).must_equal "group_username"
      end
      it 'should prefer model username group setting over normal group one' do
        Oxidized.config.username = "global_username"
        Oxidized.config.models[model].username = "model_username"
        Oxidized.config.groups[group].username = "group_username"
        Oxidized.config.groups[group].models[model].username = "group_model_username"
        _(node.auth[:username]).must_equal "group_model_username"
      end
      it 'should prefer node username over everything else' do
        Oxidized.config.username = "global_username"
        Oxidized.config.models[model].username = "model_username"
        Oxidized.config.groups[group].username = "group_username"
        Oxidized.config.groups[group].models[model].username = "group_model_username"
        node = Oxidized::Node.new(ip: '127.0.0.1', group: group, model: model, username: "node_username")
        _(node.auth[:username]).must_equal "node_username"
      end
    end
  end

  describe '#resolve_input' do
    it 'resolves input.default without whitespaces' do
      Oxidized.config.input.default = 'ssh,telnet,ftp'

      input_classes = @node.send(:resolve_input, {})
      _(input_classes[0]).must_equal Oxidized::SSH
      _(input_classes[1]).must_equal Oxidized::Telnet
      _(input_classes[2]).must_equal Oxidized::FTP
    end

    it 'resolves input.default with whitespaces' do
      Oxidized.config.input.default = "ssh  , \ttelnet, ftp ,scp"

      input_classes = @node.send(:resolve_input, {})
      _(input_classes[0]).must_equal Oxidized::SSH
      _(input_classes[1]).must_equal Oxidized::Telnet
      _(input_classes[2]).must_equal Oxidized::FTP
      _(input_classes[3]).must_equal Oxidized::SCP
    end
  end
end
