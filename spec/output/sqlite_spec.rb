require_relative '../spec_helper'
require 'oxidized/output/sqlite'
require 'tmpdir'

describe 'Oxidized::Output::SQLite' do
  before(:each) do
    Oxidized.asetus = Asetus.new
    @tmpdir = Dir.mktmpdir('oxidized_sqlite_output_test')
    @db_path = File.join(@tmpdir, 'test_configs.db')
    Oxidized.config.output.sqlite.database = @db_path
    @sqlite = Oxidized::Output::SQLite.new
    @outputs = Oxidized::Model::Outputs.new
    @outputs << 'test configuration'
  end

  after(:each) do
    @sqlite&.close
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.directory?(@tmpdir)
  end

  describe '#setup' do
    it 'raises Oxidized::NoConfig when no config is provided' do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)
      Asetus.any_instance.expects(:save)

      Oxidized::Config.load({ home_dir: '/cfg_path/' })
      Oxidized.config.output.sqlite = ''
      output = Oxidized::Output::SQLite.new

      err = _(-> { output.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_match(/^no output sqlite config, edit \/cfg_path\/config$/)
    end
  end

  describe '#store' do
    it 'stores configuration in SQLite database' do
      @sqlite.store('router1', @outputs)

      config = @sqlite.fetch('router1', nil)
      _(config).must_equal 'test configuration'
    end

    it 'stores configuration with group' do
      @sqlite.store('router1', @outputs, { group: 'datacenter1' })

      config = @sqlite.fetch('router1', 'datacenter1')
      _(config).must_equal 'test configuration'
    end

    it 'updates configuration when changed' do
      @sqlite.store('router1', @outputs)

      new_outputs = Oxidized::Model::Outputs.new
      new_outputs << 'updated configuration'
      @sqlite.store('router1', new_outputs)

      config = @sqlite.fetch('router1', nil)
      _(config).must_equal 'updated configuration'
    end

    it 'does not update when configuration is unchanged' do
      @sqlite.store('router1', @outputs)

      # Get version count
      versions = @sqlite.version('router1', nil)
      initial_count = versions.length

      @sqlite.store('router1', @outputs)

      versions = @sqlite.version('router1', nil)
      _(versions.length).must_equal initial_count
    end

    it 'creates version history when configuration changes' do
      @sqlite.store('router1', @outputs)

      new_outputs = Oxidized::Model::Outputs.new
      new_outputs << 'version 2'
      @sqlite.store('router1', new_outputs)

      new_outputs2 = Oxidized::Model::Outputs.new
      new_outputs2 << 'version 3'
      @sqlite.store('router1', new_outputs2)

      versions = @sqlite.version('router1', nil)
      _(versions.length).must_be :>=, 2
    end
  end

  describe '#fetch' do
    it 'returns nil when node not found' do
      config = @sqlite.fetch('nonexistent', nil)
      _(config).must_be_nil
    end

    it 'fetches configuration for specific group' do
      @sqlite.store('router1', @outputs, { group: 'group1' })

      config = @sqlite.fetch('router1', 'group1')
      _(config).must_equal 'test configuration'

      # Different group should not find it
      config = @sqlite.fetch('router1', 'group2')
      _(config).must_be_nil
    end
  end

  describe '#version' do
    it 'returns empty array when no versions exist' do
      versions = @sqlite.version('router1', nil)
      _(versions).must_equal []
    end

    it 'returns version history with oid, date, and author' do
      @sqlite.store('router1', @outputs)

      versions = @sqlite.version('router1', nil)
      _(versions.length).must_equal 1
      _(versions.first).must_include :oid
      _(versions.first).must_include :date
      _(versions.first).must_include :author
      _(versions.first[:author]).must_equal 'oxidized'
    end

    it 'returns versions in descending order' do
      @sqlite.store('router1', @outputs)
      sleep 0.1

      new_outputs = Oxidized::Model::Outputs.new
      new_outputs << 'version 2'
      @sqlite.store('router1', new_outputs)

      versions = @sqlite.version('router1', nil)
      _(versions.first[:date]).must_be :>, versions.last[:date]
    end

    it 'limits version history to 100 entries' do
      105.times do |i|
        outputs = Oxidized::Model::Outputs.new
        outputs << "config version #{i}"
        @sqlite.store('router1', outputs)
      end

      versions = @sqlite.version('router1', nil)
      _(versions.length).must_equal 100
    end
  end

  describe '#get_version' do
    it 'returns specific version by oid' do
      @sqlite.store('router1', @outputs)
      versions = @sqlite.version('router1', nil)
      oid = versions.first[:oid]

      config = @sqlite.get_version('router1', nil, oid)
      _(config).must_equal 'test configuration'
    end

    it 'returns error message for invalid oid' do
      config = @sqlite.get_version('router1', nil, '99999')
      _(config).must_equal 'version not found'
    end
  end

  describe '.clean_obsolete_nodes' do
    before do
      @opts = {
        input:  'ssh',
        output: 'sqlite',
        model:  'junos'
      }
    end

    it 'removes configurations for obsolete nodes' do
      # Store configs for 3 nodes
      %w[node1 node2 node3].each do |node|
        @sqlite.store(node, @outputs)
      end

      # Create active nodes list with only node1 and node2
      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

      Oxidized::Output::SQLite.clean_obsolete_nodes(nodes)

      # node1 and node2 should exist
      _(@sqlite.fetch('node1', nil)).wont_be_nil
      _(@sqlite.fetch('node2', nil)).wont_be_nil

      # node3 should be removed
      _(@sqlite.fetch('node3', nil)).must_be_nil
    end

    it 'removes obsolete nodes with groups' do
      @sqlite.store('node1', @outputs, { group: 'gr1' })
      @sqlite.store('node2', @outputs, { group: 'gr1' })
      @sqlite.store('node3', @outputs, { group: 'gr2' })

      nodes = [
        Oxidized::Node.new(@opts.merge(name: 'node1', group: 'gr1')),
        Oxidized::Node.new(@opts.merge(name: 'node2', group: 'gr1'))
      ]

      Oxidized::Output::SQLite.clean_obsolete_nodes(nodes)

      _(@sqlite.fetch('node1', 'gr1')).wont_be_nil
      _(@sqlite.fetch('node2', 'gr1')).wont_be_nil
      _(@sqlite.fetch('node3', 'gr2')).must_be_nil
    end

    it 'removes version history for obsolete nodes' do
      # Create multiple versions for node1
      3.times do |i|
        outputs = Oxidized::Model::Outputs.new
        outputs << "config #{i}"
        @sqlite.store('node1', outputs)
      end

      nodes = []
      Oxidized::Output::SQLite.clean_obsolete_nodes(nodes)

      versions = @sqlite.version('node1', nil)
      _(versions).must_equal []
    end
  end

  describe 'database security' do
    it 'creates database with secure permissions' do
      @sqlite.store('router1', @outputs)
      @sqlite.close

      stat = File.stat(@db_path)
      mode = "%o" % stat.mode
      _(mode).must_match(/600$/)
    end

    it 'creates database directory if it does not exist' do
      db_path = File.join(@tmpdir, 'nested', 'dir', 'configs.db')
      Oxidized.config.output.sqlite.database = db_path

      sqlite = Oxidized::Output::SQLite.new
      sqlite.store('router1', @outputs)
      sqlite.close

      _(File.exist?(db_path)).must_equal true
      _(File.directory?(File.dirname(db_path))).must_equal true
    end
  end

  describe 'database features' do
    it 'uses WAL mode for concurrency' do
      @sqlite.store('router1', @outputs)

      db = @sqlite.instance_variable_get(:@db)
      journal_mode = db.fetch("PRAGMA journal_mode").first[:journal_mode]
      _(journal_mode).must_equal 'wal'
    end

    it 'maintains schema version' do
      @sqlite.store('router1', @outputs)

      db = @sqlite.instance_variable_get(:@db)
      version = db[:schema_info].max(:version)
      _(version).must_equal Oxidized::Output::SQLite::SCHEMA_VERSION
    end
  end
end
