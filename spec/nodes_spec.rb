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
