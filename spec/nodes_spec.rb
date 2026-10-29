require_relative 'spec_helper'

describe Oxidized::Nodes do
  before(:each) do
    Resolv.any_instance.stubs(:getaddress)
    Oxidized.asetus = Asetus.new

    opts = {
      input:    'ssh',
      output:   'git',
      model:    'junos',
      username: 'alma',
      password: 'armud',
      prompt:   'test_prompt'
    }

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    @nodes_org = %w[ltt-pe1.hel kes2-rr1.tku tor-peer1.oul
                    hal-p2.tre sav-gr1-sw1.kuo psl-sec-pe1.hel].map { |e| Oxidized::Node.new(opts.merge(name: e)) }
    @node = @nodes_org.delete_at(0)
    @nodes = Oxidized::Nodes.new(nodes: @nodes_org.dup)
  end

  describe '#node_want?' do
    it 'allows a full inventory reload without cleaning output history' do
      previous_manager = Oxidized.mgr
      source_config = mock('source config')
      source_config.stubs(:default).returns(:csv)
      output_config = mock('output config')
      config = mock('config')
      config.stubs(:source).returns(source_config)
      config.stubs(:output).returns(output_config)
      Oxidized.stubs(:config).returns(config)

      loader = mock('source loader')
      loader.expects(:load).with(nil).returns([])
      source_class = mock('source class')
      source_class.expects(:new).returns(loader)
      manager = mock('manager')
      manager.expects(:add_source).with(:csv).returns(true)
      manager.stubs(:source).returns(csv: source_class)
      Oxidized.mgr = manager
      Oxidized::Output.expects(:clean_obsolete_nodes).never

      nodes = Oxidized::Nodes.new(nodes: [])
      nodes.load(nil, clean_obsolete: false)

      _(nodes).must_be_empty
    ensure
      Oxidized.mgr = previous_manager
    end
    it 'does not log credential columns when a model cannot load' do
      previous_manager = Oxidized.mgr
      source_config = mock('source config')
      source_config.stubs(:default).returns(:csv)
      output_config = mock('output config')
      output_config.stubs(:clean_obsolete_nodes?).returns(false)
      config = mock('config')
      config.stubs(:source).returns(source_config)
      config.stubs(:output).returns(output_config)
      config.stubs(:resolve_dns?).returns(false)
      config.stubs(:groups).returns({})
      config.stubs(:models).returns({})
      Oxidized.stubs(:config).returns(config)

      source_row = {
        name: 'edge-1', ip: '192.0.2.1', model: 'missing-model',
        username: 'collector', password: 'private-password'
      }
      loader = mock('source loader')
      loader.expects(:load).with(nil).returns([source_row])
      source_class = mock('source class')
      source_class.expects(:new).returns(loader)
      manager = mock('manager')
      manager.expects(:add_source).with(:csv).returns(true)
      manager.stubs(:source).returns(csv: source_class)
      manager.stubs(:model).returns({})
      manager.expects(:add_model).with('missing-model').returns(false)
      Oxidized.mgr = manager

      Oxidized::Nodes.logger.expects(:error).with(
        "node edge-1 raised Oxidized::ModelNotFound with message 'missing-model not found for node 192.0.2.1'"
      )
      @nodes.load
    ensure
      Oxidized.mgr = previous_manager
    end
    it 'wants every node when node_want is nil' do
      _(@nodes.node_want?(nil, { name: 'router1' })).must_equal true
    end

    it 'matches the node name' do
      _(@nodes.node_want?('router1', { name: 'router1' })).must_equal true
      _(@nodes.node_want?('router2', { name: 'router1' })).must_equal false
    end

    it 'does not match partial node names' do
      _(@nodes.node_want?('router10', { name: 'router1' })).must_equal false
      _(@nodes.node_want?('router1', { name: 'router10' })).must_equal false
      _(@nodes.node_want?('router1.example.com', { name: 'router1' })).must_equal false
    end

    it 'does not interpret the node name as a regexp' do
      _(@nodes.node_want?('router1', { name: 'r.uter1' })).must_equal false
    end

    it 'matches an IP address used as node name' do
      _(@nodes.node_want?('10.0.0.1', { name: '10.0.0.1' })).must_equal true
      _(@nodes.node_want?('10.0.0.10', { name: '10.0.0.1' })).must_equal false
    end

    it 'matches the IP address of the node' do
      node = { name: 'router1', ip: '10.0.0.1' }
      _(@nodes.node_want?('10.0.0.1', node)).must_equal true
      _(@nodes.node_want?('10.0.0.2', node)).must_equal false
    end
  end

  describe '#put' do
    it 'adds node to top of queue' do
      @nodes.put @node
      _(@nodes).must_equal [@node] + @nodes_org
    end
  end

  describe '#get' do
    it 'returns node from top of queue' do
      _(@nodes.get).must_equal @nodes_org.first
    end
    it 'moves node from top to bottom' do
      @nodes.get
      _(@nodes.last).must_equal @nodes_org.first
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.get
      _(before).must_equal @nodes.size
    end
  end

  describe '#next' do
    before(:each) do
      Oxidized::Nodes.logger.expects(:info)
                     .with('Add node sav-gr1-sw1.kuo to running jobs')
    end
    it 'moves node to top of queue' do
      node = @nodes[3]
      @nodes.next node.name
      _(@nodes.first).must_equal node
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.next @nodes[3].name
      _(before).must_equal @nodes.size
    end
  end
end
