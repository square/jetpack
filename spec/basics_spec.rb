require 'spec_helper'
require 'tmpdir'

describe 'jetpack - basics' do
  before(:all) do
    reset
    @project = 'spec/sample_projects/no_dependencies'
    @result = x!("bin/jetpack #{@project}")
  end

  after(:all) do
    reset
  end

  it 'will put the jruby jar under vendor' do
    expect(@result[:stderr]).to eq('')
    expect(@result[:exitstatus]).to eq(0)
    expect(File.exist?("#{@project}/vendor/jruby.jar")).to be_truthy
  end

  describe 'creates a ruby script that' do
    it 'allows you to execute using the jruby jar' do
      rake_result = x("#{@project}/bin/ruby --version")
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).to include('jruby')
      expect(rake_result[:exitstatus]).to eq(0)
    end

    it 'does not spawn a new PID' do
      # This makes writing daemon wrappers around bin/ruby much easier.
      Dir.mktmpdir do |dir|
        tmpfile = File.join(dir, 'test_pid')
        # Use exec so that we replace the "shell" process that Travis creates
        pid = Process.spawn("exec #{@project}/bin/ruby -e 'puts Process.pid'", STDOUT => tmpfile)
        Process.wait(pid)
        expect(pid).to eq(File.read(tmpfile).chomp.to_i)
      end
    end
  end
end
