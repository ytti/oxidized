# Model unit tests
Model unit tests are stored in this directory. Each test is named after the
model with `_spec.rb` appended at the end.

## Writing a model unit test with model_helper_spec.rb
Although you can write your model unit test yourself according to your specific
needs, we have a [helper](model_helper_spec.rb) which facilitates the task.

You need a [YAML simulation file](/examples/device-simulation/) for your
device, stored under `/examples/device-simulation/. See the link on how to
produce it.

The unit test is a Ruby script in the directory `/spec/model/`. It is named
`<model>_spec.rb`, for the ios model (which we will use as an example below):
[ios_spec.rb](/spec/model/ios_spec.rb). You can add more tests if you like, we
describe a minimal example here.

The model unit test feeds the oxidized model with the command outputs in the
YAML simulation file and compares the result to the section `oxidized_output`
of the YAML simulation file. You will learn below how to write the section
`oxidized_output`.

## Setting your environmment up to be able to run unit tests
Have a look at
[How to contribute content](/CONTRIBUTING.md#how-to-contribute-content). Here
is a summary of the commands to be executed:
```shell
# Fork the repository in github
git clone git@github.com:##yourname##/oxidized.git
cd oxidized
git checkout -b new_model
bundle config set --local path 'vendor/bundle'
bundle install
```

## Writing the model
Here is the skeleton of a very simple model. Copy & paste, adapt and save it to
the file `/spec/model/<modelname>_spec.rb`.

You will need to change the model name (`describe 'model/IOS' do` and
`model: 'ios'`), the name of the test
(`it 'runs on C9800-L-F-K9 with IOS-XE 17.06.05' do`) and the link to the YAML
file (`mockmodel = MockSsh.new('examples/device-simulation/yaml/<file>.yaml')`).

```ruby
require_relative 'model_helper'

describe 'model/IOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'ios')
  end

  it 'runs on C9800-L-F-K9 with IOS-XE 17.06.05' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9800-L-F-K9_17.06.05.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    # result2file(result, 'model-output.txt')
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
```

## Run the unit test
You can run the unit test with `bundle exec rake`, it will fail:

```shell
~/oxidized$ bundle exec rake
Running RuboCop...
Inspecting 240 files
................................................................................
................................................................................
................................................................................

240 files inspected, no offenses detected
/usr/bin/ruby3.1 -I"lib:spec" /home/user/oxidized/vendor/bundle/ruby/3.1.0/gems/rake-13.2.1/lib/rake/
rake_test_loader.rb "spec/cli_spec.rb" "spec/hook/githubrepo_spec.rb" "spec/input/ssh_spec.rb" "spec/model/aosw_spec.rb" "spec/model/apc_aos_spec.rb" "spec/model/garderos_spec.rb" "spec/model/ios_spec.rb" "spec/model/model_helper_spec.rb" "spec/node_spec.rb" "spec/nodes_spec.rb" "spec/output/git_spec.rb" "spec/refinements_spec.rb" "spec/source/http_spec.rb"
Run options: --seed 57029

# Running:

..........F...................SS..........................S..S....S

Finished in 2.555600s, 26.2169 runs/s, 63.7815 assertions/s.

  1) Failure:
model/IOS#test_0003_runs on C9800-L-F-K9 with IOS-XE 17.06.05 [spec/model/ios_spec.rb:35]:
--- expected
+++ actual
@@ -1 +1,156 @@
-"!! needs to be written by hand or copy & paste from model output"
+"! Cisco IOS XE Software, Version 17.06.05
+! 
+! Image: Software: C9800_IOSXE-K9, 17.6.5, RELEASE SOFTWARE (fc2)
+! Image: Compiled: Wed 25-Jan-23 16:09 by mcpre
+! Image: bootflash:C9800-L-universalk9_wlc.17.06.05.SPA.bin
(...)
+netconf-yang
+end
+
+"


67 runs, 163 assertions, 1 failures, 0 errors, 5 skips
(...)
```

It fails because we haven't specified the expected output in the YAML file. As
this is a tedious task, we can make oxidized write it for us. For this, we
uncomment the line `# result2file(result, 'model-output.txt')` in the unit test.
It will save the output in the file `model-output.txt in the oxidized directory
next time you run the test.

You can check the output, modify it or modify you model an re-run the test.
When you are happy with it, copy and paste it in the section `oxidized_output`
of the YAML simulation file:
```yaml
---
# ...
oxidized_output: |
  ! Cisco IOS XE Software, Version 17.06.05
  !\x20
  ! Image: Software: C9800_IOSXE-K9, 17.6.5, RELEASE SOFTWARE (fc2)
  ! (...)
    netconf-yang
  end\n
# End of YAML file
```

There are a few things in the example above to pay attention to:
- Most of the outputs end with a trailing line feed (`\n`). This is addressed
by using `oxidized_output: |` instead of `oxidized_output: |-`, which would
strip the trailing line feed.
- Cisco IOS ends its config with two line feeds, so I added an extra one at the
end of the output.
- The comment `# End of YAML file` is optional, I use it to make sure I don't
have some garbage added by my editor.

## Re-run the unit test
Now, remove the line `result2file(result, 'model-output.txt')` and the file
`model-output.txt`, and re-run the test. It should be successful:
```shell
~/oxidized$ bundle exec rake
Running RuboCop...
Inspecting 240 files
................................................................................
................................................................................
................................................................................

240 files inspected, no offenses detected
/usr/bin/ruby3.1 -I"lib:spec" /home/user/oxidized/vendor/bundle/ruby/3.1.0/gems/rake-13.2.1/lib/rake/rake_test_loader.rb "spec/cli_spec.rb" "spec/hook/githubrepo_spec.rb" "spec/input/ssh_spec.rb" "spec/model/aosw_spec.rb" "spec/model/apc_aos_spec.rb" "spec/model/garderos_spec.rb" "spec/model/ios_spec.rb" "spec/model/model_helper_spec.rb" "spec/node_spec.rb" "spec/nodes_spec.rb" "spec/output/git_spec.rb" "spec/refinements_spec.rb" "spec/source/http_spec.rb"
Run options: --seed 12233

# Running:

.......................S.S...................S.........SS..........

Finished in 2.552535s, 26.2484 runs/s, 63.8581 assertions/s.

67 runs, 163 assertions, 0 failures, 0 errors, 5 skips

You have skipped tests. Run with --verbose for details.
Coverage report generated for RSpec to /home/oxidized/oxidized/coverage/coverage.xml. 1447 / 2169 LOC (66.71%) covered
Coverage report generated for RSpec to /home/oxidized/oxidized/coverage. 1447 / 2169 LOC (66.71%) covered.
```

If not, you will get an output of the differences and have to look into them.

## Extend your test with a second device for the model
If you want the test to run against a second device, you will need a second
YAML simulation file, and you need to add a new `it 'test description' do`
to your test:
```ruby
  it 'runs on C9200L-24P-4G with IOS-XE 17.09.04a' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9200L-24P-4G_17.09.04a.yaml'
)
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
```

## Test different prompts
You can also test your prompt regexp against different prompts with a specific
`it...` section:

```ruby
  it 'matches different prompts' do
    _('LAB-SW123_9200L#').must_match IOS.prompt
    _('OXIDIZED-WLC1#').must_match IOS.prompt
  end
```

## Improve your oxidized output
Now you can edit the YAML file to specify the oxidized output you'd like to get,
and adjust your oxidized model until it outputs exactly the output you've
specified. Running `bundle exec rake` will check this for you and show you the
differences.

Welcome to the beautiful world of Test-driven development (TDD)! ;-)

## Information about unit tests in oxidized
The unit tests use
[minitest/spec](https://github.com/minitest/minitest?tab=readme-ov-file#specs-)
and [mocha](https://github.com/freerange/mocha).
If you need more expectations for your tests, have a look at the
[minitest documentation for expectations](https://docs.seattlerb.org/minitest/Minitest/Expectations.html)
