require_relative 'spec_helper'
require 'oxidized/job'

describe Oxidized::Job do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.config.timelimit = 300
  end
  it "gets a status :timelimit when the job timelimit is reached" do
    node = mock("Oxidized::Node")
    node.expects(:name).returns("SW123").times(3)
    node.expects(:run).raises(Timeout::Error)

    Oxidized::Job.logger.expects(:warn).with('Job timelimit reached for SW123')

    job = Oxidized::Job.new(node)
    job.join

    _(job.status).must_equal :timelimit
    _(job.config).must_be_nil
  end

  it "gets a status :success when fetching was OK" do
    node = mock("Oxidized::Node")
    node.expects(:name).returns("SW123").times(3)
    node.expects(:run).returns([:success, "config-data"])

    start_time = Time.now.utc
    job = Oxidized::Job.new(node)
    job.join
    end_time = Time.now.utc

    _(job.status).must_equal :success
    _(job.config).must_equal "config-data"
    _(job.start).must_be_close_to start_time, 1
    _(job.end).must_be_close_to end_time, 1
    _(job.time).must_be :>=, 0
  end
end
