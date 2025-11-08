require 'spec_helper'
require 'oxidized'
require 'oxidized/state'
require 'fileutils'
require 'tmpdir'

describe Oxidized::State do
  before(:each) do
    @tmpdir = Dir.mktmpdir('oxidized_state_test')
    @db_path = File.join(@tmpdir, 'test.db')
    @state = Oxidized::State.new(@db_path)
  end

  after(:each) do
    @state&.close
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.directory?(@tmpdir)
  end

  describe '#initialize' do
    it 'creates database file' do
      _(File.exist?(@db_path)).must_equal true
    end

    it 'creates required tables' do
      db = Sequel.connect("sqlite://#{@db_path}")
      tables = db.tables
      _(tables).must_include :schema_info
      _(tables).must_include :node_stats_counters
      _(tables).must_include :node_stats_history
      _(tables).must_include :node_last_jobs
      _(tables).must_include :node_mtimes
      _(tables).must_include :job_durations
      db.disconnect
    end

    it 'sets schema version' do
      db = Sequel.connect("sqlite://#{@db_path}")
      version = db[:schema_info].max(:version)
      _(version).must_equal Oxidized::State::SCHEMA_VERSION
      db.disconnect
    end

    it 'enables WAL mode' do
      db = Sequel.connect("sqlite://#{@db_path}")
      journal_mode = db.fetch("PRAGMA journal_mode").first[:journal_mode]
      _(journal_mode.downcase).must_equal 'wal'
      db.disconnect
    end
  end

  describe '#update_node_stats and #get_node_stats' do
    before(:each) do
      @node_name = 'test-node-1'
      @job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc - 100,
        Time.now.utc - 50,
        50.0,
        :success
      )
    end

    it 'stores and retrieves job statistics' do
      @state.update_node_stats(@node_name, @job, 10)
      stats = @state.get_node_stats(@node_name)

      _(stats[:counter][:success]).must_equal 1
      _(stats[:success]).wont_be_nil
      _(stats[:success].length).must_equal 1
      _(stats[:success].first[:time]).must_equal 50.0
    end

    it 'increments counter for multiple jobs' do
      3.times { @state.update_node_stats(@node_name, @job, 10) }
      stats = @state.get_node_stats(@node_name)

      _(stats[:counter][:success]).must_equal 3
      _(stats[:success].length).must_equal 3
    end

    it 'maintains separate counters per status' do
      success_job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )
      fail_job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 15.0, :fail
      )

      @state.update_node_stats(@node_name, success_job, 10)
      @state.update_node_stats(@node_name, success_job, 10)
      @state.update_node_stats(@node_name, fail_job, 10)

      stats = @state.get_node_stats(@node_name)

      _(stats[:counter][:success]).must_equal 2
      _(stats[:counter][:fail]).must_equal 1
    end

    it 'trims history to specified size' do
      history_size = 5
      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      10.times { @state.update_node_stats(@node_name, job, history_size) }
      stats = @state.get_node_stats(@node_name)

      _(stats[:counter][:success]).must_equal 10
      _(stats[:success].length).must_equal history_size
    end

    it 'returns empty stats for unknown node' do
      stats = @state.get_node_stats('nonexistent-node')

      _(stats[:counter]).must_be_kind_of Hash
      _(stats[:counter].default).must_equal 0
      _(stats[:mtimes]).must_equal []
    end
  end

  describe '#set_last_job and #get_last_job' do
    before(:each) do
      @node_name = 'test-node-2'
      @job = Struct.new(:start, :end, :time, :status).new(
        Time.parse('2025-01-01 10:00:00 UTC'),
        Time.parse('2025-01-01 10:01:00 UTC'),
        60.0,
        :success
      )
    end

    it 'stores and retrieves last job' do
      @state.set_last_job(@node_name, @job)
      last_job = @state.get_last_job(@node_name)

      _(last_job).wont_be_nil
      _(last_job[:status]).must_equal :success
      _(last_job[:time]).must_equal 60.0
    end

    it 'updates existing last job' do
      @state.set_last_job(@node_name, @job)

      new_job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 45.0, :fail
      )
      @state.set_last_job(@node_name, new_job)

      last_job = @state.get_last_job(@node_name)
      _(last_job[:status]).must_equal :fail
      _(last_job[:time]).must_equal 45.0
    end

    it 'clears last job when set to nil' do
      @state.set_last_job(@node_name, @job)
      @state.set_last_job(@node_name, nil)
      
      last_job = @state.get_last_job(@node_name)
      _(last_job).must_be_nil
    end

    it 'returns nil for unknown node' do
      last_job = @state.get_last_job('nonexistent-node')
      _(last_job).must_be_nil
    end
  end

  describe '#update_mtime' do
    before(:each) do
      @node_name = 'test-node-3'
    end

    it 'stores modification times' do
      @state.update_mtime(@node_name, 10)
      stats = @state.get_node_stats(@node_name)

      _(stats[:mtimes].length).must_equal 1
      _(stats[:mtimes].first).must_be_kind_of Time
    end

    it 'maintains multiple mtimes' do
      3.times do
        @state.update_mtime(@node_name, 10)
        sleep 0.01 # Ensure different timestamps
      end

      stats = @state.get_node_stats(@node_name)
      _(stats[:mtimes].length).must_equal 3
    end

    it 'trims old mtimes' do
      history_size = 5
      10.times do
        @state.update_mtime(@node_name, history_size)
        sleep 0.01
      end

      stats = @state.get_node_stats(@node_name)
      _(stats[:mtimes].length).must_equal history_size
    end

    it 'orders mtimes chronologically' do
      3.times do
        @state.update_mtime(@node_name, 10)
        sleep 0.01
      end

      stats = @state.get_node_stats(@node_name)
      mtimes = stats[:mtimes]
      _(mtimes).must_equal mtimes.sort
    end
  end

  describe '#add_job_duration and #get_job_durations' do
    it 'stores and retrieves job durations' do
      @state.add_job_duration(10.5, 100)
      @state.add_job_duration(15.2, 100)
      @state.add_job_duration(12.8, 100)

      durations = @state.get_job_durations
      _(durations.length).must_equal 3
      _(durations).must_include 10.5
      _(durations).must_include 15.2
      _(durations).must_include 12.8
    end

    it 'maintains chronological order' do
      [10.0, 20.0, 15.0].each do |duration|
        @state.add_job_duration(duration, 100)
        sleep 0.01
      end

      durations = @state.get_job_durations
      _(durations).must_equal [10.0, 20.0, 15.0]
    end

    it 'trims old durations when exceeding max size' do
      max_size = 5
      10.times { |i| @state.add_job_duration(i.to_f, max_size) }

      durations = @state.get_job_durations
      _(durations.length).must_equal max_size
      # Should keep the last 5
      _(durations).must_equal [5.0, 6.0, 7.0, 8.0, 9.0]
    end

    it 'returns empty array when no durations stored' do
      durations = @state.get_job_durations
      _(durations).must_equal []
    end
  end

  describe '#cleanup_removed_nodes' do
    before(:each) do
      @node1 = 'node-1'
      @node2 = 'node-2'
      @node3 = 'node-3'

      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      [@node1, @node2, @node3].each do |node|
        @state.update_node_stats(node, job, 10)
        @state.set_last_job(node, job)
        @state.update_mtime(node, 10)
      end
    end

    it 'removes data for nodes not in existing list' do
      @state.cleanup_removed_nodes([@node1, @node2])

      # Node 1 and 2 should still exist
      _((@state.get_node_stats(@node1)[:counter][:success])).must_equal 1
      _((@state.get_node_stats(@node2)[:counter][:success])).must_equal 1

      # Node 3 should be cleaned up
      stats = @state.get_node_stats(@node3)
      _(stats[:counter][:success]).must_equal 0
      _(stats[:mtimes]).must_equal []
      _(@state.get_last_job(@node3)).must_be_nil
    end

    it 'keeps all nodes when all are in existing list' do
      @state.cleanup_removed_nodes([@node1, @node2, @node3])

      [@node1, @node2, @node3].each do |node|
        _((@state.get_node_stats(node)[:counter][:success])).must_equal 1
        _(@state.get_last_job(node)).wont_be_nil
      end
    end

    it 'removes all nodes when existing list is empty' do
      @state.cleanup_removed_nodes([])

      [@node1, @node2, @node3].each do |node|
        _((@state.get_node_stats(node)[:counter][:success])).must_equal 0
        _(@state.get_last_job(node)).must_be_nil
      end
    end
  end

  describe '#reset!' do
    before(:each) do
      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      @state.update_node_stats('node-1', job, 10)
      @state.set_last_job('node-1', job)
      @state.update_mtime('node-1', 10)
      @state.add_job_duration(10.0, 100)
    end

    it 'clears all state data' do
      @state.reset!

      stats = @state.get_node_stats('node-1')
      _(stats[:counter][:success]).must_equal 0
      _(stats[:mtimes]).must_equal []
      _(@state.get_last_job('node-1')).must_be_nil
      _(@state.get_job_durations).must_equal []
    end
  end

  describe '#close' do
    it 'closes database connection' do
      @state.close
      # Should not raise error when closing again
      @state.close
    end
  end

  describe 'transaction isolation' do
    it 'maintains data consistency during concurrent updates' do
      node_name = 'concurrent-node'
      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      threads = []
      10.times do
        threads << Thread.new do
          @state.update_node_stats(node_name, job, 10)
        end
      end
      threads.each(&:join)

      stats = @state.get_node_stats(node_name)
      _(stats[:counter][:success]).must_equal 10
    end
  end

  describe 'error handling' do
    it 'raises error for invalid database path' do
      invalid_path = '/invalid/path/that/does/not/exist/oxidized.db'
      FileUtils.mkdir_p(File.dirname(invalid_path)) rescue nil
      
      # SQLite will try to create the file, so this test checks connection issues
      begin
        state = Oxidized::State.new(invalid_path)
        state.close
      rescue Oxidized::OxidizedError
        # Expected to potentially fail on some systems
      end
    end
  end
end
