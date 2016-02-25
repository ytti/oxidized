require 'spec_helper'
require 'oxidized/output/file'

describe Oxidized::OxidizedFile do
  subject { Oxidized::OxidizedFile.new }
  let(:config) { 'this is a command output\nModel: mx960' }
  let(:outputs) { mock('output') }
  let(:file) { "#{directory}/#{node}" }
  let(:base) { '/directory' }
  let(:node) { 'node' }
  let(:fh) { mock('fh') }

  before do
    Oxidized.stubs(:asetus).returns(Asetus.new)
    Oxidized.config.output.file.directory = base
  end

  describe '#store' do
    before do
      outputs.expects(:to_cfg).returns(config)
      fh.expects(:write).with(config)
      FileUtils.expects(:mkdir_p).with(directory)
      File.expects(:open).with(file, 'w').yields(fh)
    end

    describe 'without a group' do
      let(:directory) { base }

      before do
        File.expects(:join).with(directory, node).returns("#{directory}/#{node}")
      end

      it 'should store a file without a group' do
        subject.store(node, outputs, {})
        subject.commitref.must_equal(file)
      end
    end

    describe 'with a group' do
      let(:directory) { "#{base}/#{group}" }
      let(:group) { 'group' }

      before do
        File.expects(:join).with(base, group).returns(directory)
        File.expects(:join).with(directory, node).returns(file)
      end

      it 'should store a file in the group directory' do
        subject.store(node, outputs, { group: group })
        subject.commitref.must_equal(file)
      end
    end
  end
end
