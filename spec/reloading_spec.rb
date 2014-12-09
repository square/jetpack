require 'spec_helper'
require 'yaml'

describe 'jetpack - reloading' do
  before(:all) do
    reset
    @result = x!('bin/jetpack spec/sample_projects/webapp_reloading')
  end

  after(:all) do
    reset
  end

  it 'uses reloading SSL' do
    expect(File.exist?('spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml')).to be_truthy
    expect(File.read('spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml')).to include("class=\"jetpack.ssl.ReloadingSslContextFactory\"")
  end

  # TODO: (@sul3n3t) - these tests don't currently work, and were not being run because of incorrect file extension :(
  # ref: https://github.com/square/jetpack/pull/33
  it 'compiled java classes' do
    pending 'These folders are not actually produced; either behavior or tests need to be fixed'
    classes_dir = 'spec/sample_projects/webapp_reloading/WEB-INF/classes'
    expect(File.exist?(classes_dir)).to be_truthy
    expect(File.exist?(File.join(classes_dir, 'jetpack/ssl/FileResolver.class'))).to be_truthy
    expect(File.exist?(File.join(classes_dir, 'jetpack/ssl/ReloadingKeyManager.class'))).to be_truthy
    expect(File.exist?(File.join(classes_dir, 'jetpack/ssl/ReloadingSslContextFactory.class'))).to be_truthy
    expect(File.exist?(File.join(classes_dir, 'jetpack/ssl/VersionedFileResolver.class'))).to be_truthy
  end

  it 'retrieved java jars' do
    pending 'These folders are not actually produced; either behavior or tests need to be fixed'
    lib_dir = 'spec/sample_projects/webapp_reloading/WEB-INF/lib'
    expect(File.exist?(lib_dir)).to be_truthy
    expect(File.exist?(File.join(lib_dir, 'guava.jar'))).to be_truthy
    expect(File.exist?(File.join(lib_dir, 'joda-time.jar'))).to be_truthy
    expect(File.exist?(File.join(lib_dir, 'slf4j-api.jar'))).to be_truthy
    expect(File.exist?(File.join(lib_dir, 'slf4j-simple.jar'))).to be_truthy
  end

  it 'runs' do
    pending "This test has incorrect expectations; netcat on the port would not produce 'Hello World'"
    pid_to_kill = run_app
    begin
      puts x!('nc localhost 19143').inspect
      expect(x!('nc localhost 19143')[:stdout]).to eq('Hello World')
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end

  def run_app
    jetty_pid = Process.spawn({ 'RAILS_ENV' => 'development' }, 'bin/launch', :chdir => 'spec/sample_projects/webapp_reloading')
    start_time = Time.now
    loop do
      begin
        TCPSocket.open('localhost', 19143)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end
