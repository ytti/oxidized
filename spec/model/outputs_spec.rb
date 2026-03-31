require_relative '../spec_helper'
require 'oxidized/model/outputs'

describe Oxidized::Model::Outputs do
  using Refinements

  def make_output(content, type: nil)
    s = String.new(content)
    s.type = type
    s
  end

  before do
    @outputs = Oxidized::Model::Outputs.new
  end

  describe '#<<' do
    it 'appends an output to the collection' do
      out = make_output('config line')
      @outputs << out
      _(@outputs.all.size).must_equal 1
      _(@outputs.all.first).must_equal 'config line'
    end

    it 'appends multiple outputs in order' do
      @outputs << make_output('first')
      @outputs << make_output('second')
      _(@outputs.all.map(&:to_s)).must_equal %w[first second]
    end
  end

  describe '#unshift' do
    it 'prepends an output before existing entries' do
      @outputs << make_output('second')
      @outputs.unshift make_output('first')
      _(@outputs.all.first).must_equal 'first'
      _(@outputs.all.last).must_equal 'second'
    end
  end

  describe '#all' do
    it 'returns an empty array when no outputs have been added' do
      _(@outputs.all).must_equal []
    end

    it 'returns all outputs regardless of type' do
      @outputs << make_output('a', type: nil)
      @outputs << make_output('b', type: 'acl')
      _(@outputs.all.size).must_equal 2
    end
  end

  describe '#type' do
    it 'filters outputs by a named type' do
      @outputs << make_output('main', type: nil)
      @outputs << make_output('acl1', type: 'acl')
      @outputs << make_output('acl2', type: 'acl')
      result = @outputs.type('acl')
      _(result.size).must_equal 2
      _(result.map(&:to_s)).must_equal %w[acl1 acl2]
    end

    it 'returns outputs with nil type when queried with nil' do
      @outputs << make_output('main', type: nil)
      @outputs << make_output('section', type: 'acl')
      result = @outputs.type(nil)
      _(result.size).must_equal 1
      _(result.first).must_equal 'main'
    end

    it 'returns an empty array when no output matches the type' do
      @outputs << make_output('main', type: nil)
      _(@outputs.type('bgp')).must_equal []
    end
  end

  describe '#types' do
    it 'returns unique non-nil types' do
      @outputs << make_output('a', type: nil)
      @outputs << make_output('b', type: 'acl')
      @outputs << make_output('c', type: 'acl')
      @outputs << make_output('d', type: 'bgp')
      _(@outputs.types.sort).must_equal %w[acl bgp]
    end

    it 'returns an empty array when all outputs have nil type' do
      @outputs << make_output('a', type: nil)
      _(@outputs.types).must_equal []
    end
  end

  describe '#to_cfg' do
    it 'joins all outputs with nil type into a single string' do
      @outputs << make_output("line1\n", type: nil)
      @outputs << make_output("line2\n", type: nil)
      @outputs << make_output("section\n", type: 'acl')
      _(@outputs.to_cfg).must_equal "line1\nline2\n"
    end

    it 'returns an empty string when there are no nil-type outputs' do
      @outputs << make_output("acl rule\n", type: 'acl')
      _(@outputs.to_cfg).must_equal ''
    end
  end

  describe '#type_to_str' do
    it 'joins outputs of a specific type into a single string' do
      @outputs << make_output("acl1\n", type: 'acl')
      @outputs << make_output("acl2\n", type: 'acl')
      @outputs << make_output("bgp1\n", type: 'bgp')
      _(@outputs.type_to_str('acl')).must_equal "acl1\nacl2\n"
    end

    it 'returns an empty string for an unknown type' do
      @outputs << make_output("acl1\n", type: 'acl')
      _(@outputs.type_to_str('ospf')).must_equal ''
    end
  end

  describe '#merge!' do
    it 'appends all outputs from another Outputs instance' do
      other = Oxidized::Model::Outputs.new
      other << make_output('x')
      other << make_output('y')
      @outputs << make_output('a')
      @outputs.merge!(other)
      _(@outputs.all.size).must_equal 3
      _(@outputs.all.map(&:to_s)).must_equal %w[a x y]
    end

    it 'returns self when merging an Outputs instance with entries' do
      other = Oxidized::Model::Outputs.new
      other << make_output('x')
      other << make_output('y')
      _(@outputs.merge!(other)).must_be_same_as @outputs
    end

    it 'leaves self unchanged when merging an empty Outputs instance' do
      @outputs << make_output('a')
      @outputs.merge!(Oxidized::Model::Outputs.new)
      _(@outputs.all.size).must_equal 1
    end

    it 'preserves type information of merged outputs' do
      other = Oxidized::Model::Outputs.new
      other << make_output('acl rule', type: 'acl')
      @outputs.merge!(other)
      _(@outputs.type('acl').size).must_equal 1
    end
  end
end
