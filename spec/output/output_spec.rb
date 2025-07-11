require_relative '../spec_helper'
require 'oxidized/output/output'
require 'oxidized/output/git'
require 'oxidized/output/file'
require 'oxidized/output/http'

describe 'Oxidized::Output' do
  describe '.clean_obsolete_nodes' do
    before do
      Oxidized.asetus = Asetus.new
    end
    it 'runs on git' do
      Oxidized.config.output.default = 'git'
      Oxidized.config.output.git.repo = 'gitrepo'
      Oxidized.config.output.clean_obsolete_nodes = true
      Oxidized::Output::Git.expects(:clean_obsolete_nodes)
      Oxidized::Output::File.expects(:clean_obsolete_nodes).never
      Oxidized::Output.clean_obsolete_nodes([])
    end
    it 'runs on file' do
      Oxidized.config.output.default = 'file'
      Oxidized.config.output.file.directory = 'configs'
      Oxidized.config.output.clean_obsolete_nodes = true
      Oxidized::Output::File.expects(:clean_obsolete_nodes)
      Oxidized::Output::Git.expects(:clean_obsolete_nodes).never
      Oxidized::Output.clean_obsolete_nodes([])
    end

    it 'runs the default method on http' do
      Oxidized.config.output.default = 'http'
      Oxidized.config.output.http.url = 'fakeurl'
      Oxidized.config.output.clean_obsolete_nodes = true
      Oxidized::Output::File.expects(:clean_obsolete_nodes).never
      Oxidized::Output::Git.expects(:clean_obsolete_nodes).never
      Oxidized::Output::Http.logger.expects(:warn)
                            .with("clean_obsolete_nodes is not " \
                                  "implemented for Oxidized::Output::Http")
      Oxidized::Output.clean_obsolete_nodes([])
    end
  end
end
