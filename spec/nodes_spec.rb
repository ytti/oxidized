require 'oxidized'
Oxidized.mgr = Oxidized::Manager.new

describe Oxidized::Nodes do
  before(:each) do
    @nodes_org = %w(ltt-pe1.hel kes2-rr1.tku tor-peer1.oul
                hal-p2.tre sav-gr1-sw1.kuo psl-sec-pe1.hel).map { |e| Oxidized::Node.new(:name=>e) }
    @nodes = Oxidized::Nodes.new @nodes_org.dup
  end

  describe '#put' do
    it 'adds node to top of queue' do
      node = Oxidized::Node.new(:name=>'kst-p1.sto')
      @nodes.put node
      expect(@nodes).to eq [node] + @nodes_org
    end
  end

  describe '#get' do
    it 'returns node from top of queue' do
      expect(@nodes.get).to eq @nodes_org.first
    end
    it 'moves node from top to bottom' do
      @nodes.get
      expect(@nodes).to end_with [@nodes_org.first]
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.get
      expect(before).to eq @nodes.size
    end
  end

  describe '#next' do
    it 'moves node to top of queue' do
      node = @nodes[3]
      @nodes.next node.name
      expect(@nodes).to start_with [node]
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.next @nodes[3].name
      expect(before).to eq @nodes.size
    end
  end
end
