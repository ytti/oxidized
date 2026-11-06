# frozen_string_literal: true

require_relative 'model_helper'
require 'oxidized/model/itmgos'

describe 'Model ITMGOS' do
  before(:each) do
    init_model_helper

    @mock_node = mock('Oxidized::Node')
    @mock_node.stubs(:name).returns('slc-1')
    @mock_node.stubs(:ip).returns('192.0.2.10')
    @mock_node.stubs(:group).returns('default')

    @mock_input = mock('Oxidized::Input')
    @mock_input.stubs(:output).returns(nil)
    @mock_input.stubs(:cmd).with('admin version').returns("admin version\r\nModel: SLC9016\r\n[slc-1]>")

    @model = ITMGOS.new
    @model.input = @mock_input
    @model.node  = @mock_node
  end

  # The command echo and the prompt frame the output, as on the device. The values are
  # fabricated.
  def export(*lines)
    ['admin config commands copypaste', 'yes', 'One moment while the file is generated...',
     *lines, '[slc-1]>'].join("\r\n")
  end

  def config(export_output, remove_secret:)
    @mock_input.stubs(:cmd).with('admin config commands copypaste').returns(export_output)
    @model.stubs(:vars).returns(nil)
    @model.stubs(:vars).with(:remove_secret).returns(remove_secret)
    @model.get.to_cfg
  end

  it 'hides prompted secrets when the command line has trailing whitespace' do
    result = config(export('set tacacs+ secret ', 'TacacsExample-1', 'TacacsExample-1',
                           'set tacacs+ state enable'), remove_secret: true)

    _(result).wont_include 'TacacsExample-1'
    _(result).must_match(/^set tacacs\+ secret \n<secret hidden>\n<secret hidden>\nset tacacs\+ state enable$/)
  end

  it 'hides a prompted secret at the end of the export' do
    @mock_input.stubs(:cmd).with('admin config commands copypaste').returns(
      export('set ldap bindpassword', 'LdapExample-2', 'LdapExample-2').sub(/\r\n\[slc-1\]>\z/, "\r\n")
    )
    @model.stubs(:vars).returns(nil)
    @model.stubs(:vars).with(:remove_secret).returns(true)

    _(@model.get.to_cfg).wont_include 'LdapExample-2'
  end

  it 'keeps a secret whose value is "yes" in the unsanitized export' do
    result = config(export('set radius server 1 secret', 'yes', 'yes', 'set radius server 1 port 1812'),
                    remove_secret: false)

    _(result).must_match(/^set radius server 1 secret\nyes\nyes\nset radius server 1 port 1812$/)
    _(result).wont_include 'One moment while the file is generated'
  end

  it 'keeps the lines after a secret whose value is "yes" when sanitizing' do
    result = config(export('set radius server 1 secret', 'yes', 'yes', 'set tacacs+ secret',
                           'TacacsExample-3', 'TacacsExample-3'), remove_secret: true)

    _(result).wont_include 'TacacsExample-3'
    _(result).must_match(/^set radius server 1 secret\n<secret hidden>\n<secret hidden>\nset tacacs\+ secret$/)
  end
end
