require_relative '../spec_helper'
require 'oxidized/output/file'
require 'fakefs/safe'

describe 'Oxidized::Output::File' do
  describe '#setup' do
    it 'raises Oxidized::NoConfig when no config is provided' do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      Oxidized.config.output.file = ''
      oxidized_file = Oxidized::Output::File.new

      err = _(-> { oxidized_file.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_match(/^no output file config, edit \/cfg_path\/config$/)
    end
  end

  describe '#store' do
    before do
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.file.directory = '/fakefs'
      Oxidized.asetus.cfg.debug = false
      Oxidized.setup_logger
      @file = Oxidized::Output::File.new
      @outputs = Oxidized::Model::Outputs.new
      @outputs << 'configuration'
    end
    it 'stores configurations in the configured folder' do
      FakeFS.with_fresh do
        Dir.mkdir('/fakefs')
        @file.store('node1', @outputs)

        _(File.exist?('/fakefs/node1')).must_equal true
        _(File.read('/fakefs/node1')).must_equal 'configuration'
      end
    end

    it 'stores group configurations in the parent folder' do
      FakeFS.with_fresh do
        Dir.mkdir('/fakefs')
        @file.store('node1', @outputs, { group: 'gr1' })

        _(File.exist?('/fakefs/node1')).must_equal false
        _(File.exist?('/gr1/node1')).must_equal true
        _(File.read('/gr1/node1')).must_equal 'configuration'
      end
    end
  end

  describe '#clean_obsolete_nodes' do
    before do
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.file.directory = '/fakefs'
      Oxidized.asetus.cfg.debug = false
      Oxidized.setup_logger
      @opts = {
        input:  'ssh',
        output: 'file',
        model:  'junos'
      }
    end

    it "removes obsolete configuration files - without groups" do
      FakeFS.with_fresh do
        Dir.mkdir('/fakefs')
        File.write('/fakefs/node1', 'Configuration')
        File.write('/fakefs/node2', 'Configuration')
        File.write('/fakefs/node3', 'Configuration')

        nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

        Oxidized::Output::File.clean_obsolete_nodes(nodes)

        _(File.exist?('/fakefs/node1')).must_equal true
        _(File.exist?('/fakefs/node2')).must_equal true
        _(File.exist?('/fakefs/node3')).must_equal false
      end
    end

    it "does not remove non-configuration files" do
      FakeFS.with_fresh do
        Dir.mkdir('/fakefs')
        Dir.mkdir('/fakefs/subdir')
        File.write('/fakefs/subdir/nonode', 'no config')
        File.write('/fakefs/.nonode', 'no config')
        File.write('/some_file', 'no config')

        nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

        Oxidized::Output::File.clean_obsolete_nodes(nodes)

        # Nodes can't be in subdirectories
        _(File.exist?('/fakefs/subdir/nonode')).must_equal true
        # Files beginning with . are not deleted
        _(File.exist?('/fakefs/.nonode')).must_equal true
        # Files outside /fakefs are not deleted
        _(File.exist?('/some_file')).must_equal true
      end
    end

    it "removes obsolete configuration files - with groups" do
      FakeFS.with_fresh do
        Dir.mkdir('/gr1')
        File.write('/gr1/node11', 'Configuration')
        File.write('/gr1/node12', 'Configuration')
        File.write('/gr1/node13', 'Configuration')
        Dir.mkdir('/gr2')
        File.write('/gr2/node21', 'Configuration')
        Dir.mkdir('/gr1/gr3')
        File.write('/gr1/gr3/node131', 'Configuration')
        File.write('/gr1/gr3/node141', 'Configuration')

        nodes = %w[node11 node12].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1')) }
        nodes << Oxidized::Node.new(@opts.merge(name: 'node131', group: 'gr1/gr3'))

        Oxidized::Output::File.clean_obsolete_nodes(nodes)

        _(File.exist?('/gr1/node11')).must_equal true
        _(File.exist?('/gr1/node12')).must_equal true
        _(File.exist?('/gr1/node13')).must_equal false
        # We don't remove from obsolete groups as it could be something else
        _(File.exist?('/gr2/node21')).must_equal true
        # Works with groups containing / (subgroups)
        _(File.exist?('/gr1/gr3/node131')).must_equal true
        _(File.exist?('/gr1/gr3/node132')).must_equal false
      end
    end
  end
end
