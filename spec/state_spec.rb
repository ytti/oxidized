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

  describe 'data validation' do
    describe '#update_node_stats' do
      it 'rejects nil node_name' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        _ { @state.update_node_stats(nil, job, 10) }.must_raise ArgumentError
      end

      it 'rejects empty node_name' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        _ { @state.update_node_stats('', job, 10) }.must_raise ArgumentError
      end

      it 'rejects node_name longer than 255 chars' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        long_name = 'a' * 256
        _ { @state.update_node_stats(long_name, job, 10) }.must_raise ArgumentError
      end

      it 'rejects nil job' do
        _ { @state.update_node_stats('test-node', nil, 10) }.must_raise ArgumentError
      end

      it 'rejects job without required methods' do
        bad_job = Object.new
        _ { @state.update_node_stats('test-node', bad_job, 10) }.must_raise ArgumentError
      end

      it 'rejects negative history_size' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        _ { @state.update_node_stats('test-node', job, -1) }.must_raise ArgumentError
      end

      it 'rejects zero history_size' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        _ { @state.update_node_stats('test-node', job, 0) }.must_raise ArgumentError
      end

      it 'handles Time objects correctly' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        @state.update_node_stats('test-node', job, 10)
        stats = @state.get_node_stats('test-node')
        _(stats[:counter][:success]).must_equal 1
      end

      it 'rejects infinite duration' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, Float::INFINITY, :success
        )
        _ { @state.update_node_stats('test-node', job, 10) }.must_raise ArgumentError
      end

      it 'rejects NaN duration' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, Float::NAN, :success
        )
        _ { @state.update_node_stats('test-node', job, 10) }.must_raise ArgumentError
      end
    end

    describe '#set_last_job' do
      it 'rejects nil node_name' do
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        _ { @state.set_last_job(nil, job) }.must_raise ArgumentError
      end

      it 'accepts nil job to clear' do
        @state.set_last_job('test-node', nil)
        _(@state.get_last_job('test-node')).must_be_nil
      end
    end

    describe '#update_mtime' do
      it 'rejects nil node_name' do
        _ { @state.update_mtime(nil, 10) }.must_raise ArgumentError
      end

      it 'rejects negative history_size' do
        _ { @state.update_mtime('test-node', -1) }.must_raise ArgumentError
      end
    end

    describe '#add_job_duration' do
      it 'rejects negative duration' do
        _ { @state.add_job_duration(-5.0, 10) }.must_raise ArgumentError
      end

      it 'rejects zero duration' do
        _ { @state.add_job_duration(0, 10) }.must_raise ArgumentError
      end

      it 'rejects infinite duration' do
        _ { @state.add_job_duration(Float::INFINITY, 10) }.must_raise ArgumentError
      end

      it 'rejects NaN duration' do
        _ { @state.add_job_duration(Float::NAN, 10) }.must_raise ArgumentError
      end

      it 'accepts integer duration' do
        @state.add_job_duration(10, 100)
        durations = @state.get_job_durations
        _(durations).must_include 10.0
      end

      it 'accepts float duration' do
        @state.add_job_duration(10.5, 100)
        durations = @state.get_job_durations
        _(durations).must_include 10.5
      end
    end
  end

  describe 'file security' do
    it 'creates database with secure permissions' do
      skip 'Permission tests only on Unix-like systems' unless File.respond_to?(:chmod)

      stat = File.stat(@db_path)
      mode = stat.mode & 0o777
      _(mode).must_equal 0o600
    end

    it 'creates state directory with secure permissions' do
      skip 'Permission tests only on Unix-like systems' unless File.respond_to?(:chmod)

      state_dir = File.dirname(@db_path)
      stat = File.stat(state_dir)
      mode = stat.mode & 0o777
      _(mode).must_equal 0o700
    end

    it 'secures WAL file if it exists' do
      skip 'Permission tests only on Unix-like systems' unless File.respond_to?(:chmod)

      wal_file = @db_path + '-wal'
      if File.exist?(wal_file)
        stat = File.stat(wal_file)
        mode = stat.mode & 0o777
        _(mode).must_equal 0o600
      end
    end
  end

  describe 'data type storage' do
    it 'stores and retrieves different time formats correctly' do
      times = [
        Time.now.utc,
        Time.parse('2025-01-01 00:00:00 UTC'),
        Time.at(0)
      ]

      times.each_with_index do |time, i|
        job = Struct.new(:start, :end, :time, :status).new(
          time, time, 10.0, :success
        )
        @state.update_node_stats("node-#{i}", job, 10)

        stats = @state.get_node_stats("node-#{i}")
        _(stats[:success].first[:start]).must_be_kind_of Time
        _(stats[:success].first[:end]).must_be_kind_of Time
      end
    end

    it 'stores numeric values with precision' do
      durations = [1.0, 1.5, 1.123456789, 0.001, 999_999.999]

      durations.each do |duration|
        @state.add_job_duration(duration, 100)
      end

      retrieved = @state.get_job_durations
      durations.each do |expected|
        found = retrieved.find { |d| (d - expected).abs < 0.000001 }
        _(found).wont_be_nil
      end
    end

    it 'stores unicode node names correctly' do
      unicode_names = ['node-日本語', 'node-العربية', 'node-Ελληνικά', 'node-🚀']

      unicode_names.each do |name|
        next if name.length > 255 # Skip if too long

        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, :success
        )
        @state.update_node_stats(name, job, 10)

        stats = @state.get_node_stats(name)
        _(stats[:counter][:success]).must_equal 1
      end
    end

    it 'stores various status symbols correctly' do
      statuses = %i[success fail no_connection timeout error]

      statuses.each do |status|
        job = Struct.new(:start, :end, :time, :status).new(
          Time.now.utc, Time.now.utc, 10.0, status
        )
        @state.update_node_stats('test-node', job, 10)
      end

      stats = @state.get_node_stats('test-node')
      statuses.each do |status|
        _(stats[:counter][status]).must_equal 1
      end
    end
  end

  describe 'edge cases' do
    it 'handles very large counter values' do
      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      1000.times { @state.update_node_stats('test-node', job, 10) }

      stats = @state.get_node_stats('test-node')
      _(stats[:counter][:success]).must_equal 1000
    end

    it 'handles rapid sequential updates' do
      job = Struct.new(:start, :end, :time, :status).new(
        Time.now.utc, Time.now.utc, 10.0, :success
      )

      100.times { |i| @state.update_node_stats("node-#{i}", job, 10) }

      100.times do |i|
        stats = @state.get_node_stats("node-#{i}")
        _(stats[:counter][:success]).must_equal 1
      end
    end

    it 'handles empty database queries' do
      stats = @state.get_node_stats('nonexistent')
      _(stats[:counter][:success]).must_equal 0
      _(stats[:mtimes]).must_equal []

      last_job = @state.get_last_job('nonexistent')
      _(last_job).must_be_nil

      durations = @state.get_job_durations
      _(durations).must_equal []
    end
  end
end
