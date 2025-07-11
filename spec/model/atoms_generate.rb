require_relative 'model_helper'

# We use empty tests because we need the mock / stub feature of minitest/mocha
# to simulate SSH in order to generate the output
describe('') do
  it('') do
    ATOMS.get(ATOMS::TestOutput, '*#simulation.yaml').each do |test|
      print "Generating output file for #{test}... "
      begin
        init_model_helper
        test.generate(MockSsh)
        puts "OK"
      rescue ATOMS::TestOutput::OutputGenerationError => e
        puts e.message
      end
    end
  end
end
