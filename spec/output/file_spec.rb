require_relative '../spec_helper'
require 'oxidized/output/file'

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
      @file = Oxidized::Output::File.new
      @outputs = Oxidized::Model::Outputs.new
      @outputs << 'configuration'
    end
    it 'stores configurations in the configured directory' do
      Dir.mktmpdir do |temp_dir|
        Oxidized.config.output.file.directory = temp_dir

        @file.store('node1', @outputs)

        _(File.exist?(File.join(temp_dir, 'node1'))).must_equal true
        _(File.read(File.join(temp_dir, 'node1'))).must_equal 'configuration'
      end
    end

    it 'stores group configurations in the parent directory' do
      Dir.mktmpdir do |temp_dir|
        config_dir = File.join(temp_dir, 'configs')
        Oxidized.config.output.file.directory = config_dir
        Dir.mkdir(config_dir)

        @file.store('node1', @outputs, { group: 'gr1' })

        _(File.exist?(File.join(temp_dir, 'node1'))).must_equal false
        _(File.exist?(File.join(temp_dir, 'gr1/node1'))).must_equal true
        _(File.read(File.join(temp_dir, 'gr1/node1'))).must_equal 'configuration'
      end
    end
  end

  describe '.clean_obsolete_nodes' do
    before do
      Oxidized.asetus = Asetus.new
      @opts = {
        input:  'ssh',
        output: 'file',
        model:  'junos'
      }
    end

    it "removes obsolete configuration files - without groups" do
      Oxidized.config.output.file.directory = '/fakefs'
      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

      Dir.expects(:glob).with('/fakefs/*').returns(['/fakefs/node1',
                                                    '/fakefs/node2',
                                                    '/fakefs/node3',
                                                    '/fakefs/directory'])

      File.expects(:file?).with('/fakefs/directory').returns(false)
      File.expects(:file?).returns(true).times(3)
      File.expects(:delete).with('/fakefs/node1').never
      File.expects(:delete).with('/fakefs/node2').never
      File.expects(:delete).with('/fakefs/node3')
      File.expects(:delete).with('/fakefs/directory').never

      Oxidized::Output::File.clean_obsolete_nodes(nodes)
    end

    it "does not remove non-configuration files" do
      Dir.mktmpdir do |temp_dir|
        config_dir = File.join(temp_dir, 'configs')
        Oxidized.config.output.file.directory = config_dir

        Dir.mkdir(config_dir)
        Dir.mkdir(File.join(config_dir, 'subdir'))
        File.write(File.join(config_dir, 'subdir/nonode'), 'no config')
        File.write(File.join(config_dir, '.nonode'), 'no config')
        File.write(File.join(temp_dir, '/some_file'), 'no config')

        nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

        Oxidized::Output::File.clean_obsolete_nodes(nodes)

        # Nodes can't be in subdirectories
        _(File.exist?(File.join(config_dir, 'subdir/nonode'))).must_equal true
        # Files beginning with . are not deleted
        _(File.exist?(File.join(config_dir, '.nonode'))).must_equal true
        # Files outside /fakefs are not deleted
        _(File.exist?(File.join(temp_dir, '/some_file'))).must_equal true
      end
    end

    it "removes obsolete configuration files - with groups" do
      Dir.mktmpdir do |temp_dir|
        config_dir = File.join(temp_dir, 'configs')
        Oxidized.config.output.file.directory = config_dir

        Dir.mkdir(config_dir)
        Dir.mkdir(File.join(temp_dir, 'gr1'))
        File.write(File.join(temp_dir, 'gr1/node11'), 'Configuration')
        File.write(File.join(temp_dir, 'gr1/node12'), 'Configuration')
        File.write(File.join(temp_dir, 'gr1/node13'), 'Configuration')
        Dir.mkdir(File.join(temp_dir, 'gr2'))
        File.write(File.join(temp_dir, 'gr2/node21'), 'Configuration')
        Dir.mkdir(File.join(temp_dir, 'gr1/gr3'))
        File.write(File.join(temp_dir, 'gr1/gr3/node131'), 'Configuration')
        File.write(File.join(temp_dir, 'gr1/gr3/node141'), 'Configuration')

        nodes = %w[node11 node12].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1')) }
        nodes << Oxidized::Node.new(@opts.merge(name: 'node131', group: 'gr1/gr3'))

        Oxidized::Output::File.clean_obsolete_nodes(nodes)

        _(File.exist?(File.join(temp_dir, 'gr1/node11'))).must_equal true
        _(File.exist?(File.join(temp_dir, 'gr1/node12'))).must_equal true
        _(File.exist?(File.join(temp_dir, 'gr1/node13'))).must_equal false
        # We don't remove from obsolete groups as it could be something else
        _(File.exist?(File.join(temp_dir, 'gr2/node21'))).must_equal true
        # Works with groups containing / (subgroups)
        _(File.exist?(File.join(temp_dir, 'gr1/gr3/node131'))).must_equal true
        _(File.exist?(File.join(temp_dir, 'gr1/gr3/node132'))).must_equal false
      end
    end
  end
end
