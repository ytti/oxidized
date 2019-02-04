require 'spec_helper'

describe Oxidized::Nodes do
  before(:each) do
    Resolv.any_instance.stubs(:getaddress)
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger

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
      @nodes.must_equal [@node] + @nodes_org
    end
  end

  describe '#get' do
    it 'returns node from top of queue' do
      @nodes.get.must_equal @nodes_org.first
    end
    it 'moves node from top to bottom' do
      @nodes.get
      @nodes.last.must_equal @nodes_org.first
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.get
      before.must_equal @nodes.size
    end
  end

  describe '#next' do
    it 'moves node to top of queue' do
      node = @nodes[3]
      @nodes.next node.name
      @nodes.first.must_equal node
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.next @nodes[3].name
      before.must_equal @nodes.size
    end
  end
end
