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
    File.exist?('spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml').should be_true
    File.read('spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml').should include("class=\"jetpack.ssl.ReloadingSslContextFactory\"")
  end

  # TODO: (@sul3n3t) - these tests don't currently work, and were not being run because of incorrect file extension :(
  # ref: https://github.com/square/jetpack/pull/33
  it 'compiled java classes' do
    pending 'These folders are not actually produced; either behavior or tests need to be fixed'
    classes_dir = 'spec/sample_projects/webapp_reloading/WEB-INF/classes'
    File.exist?(classes_dir).should be_true
    File.exist?(File.join(classes_dir, 'jetpack/ssl/FileResolver.class')).should be_true
    File.exist?(File.join(classes_dir, 'jetpack/ssl/ReloadingKeyManager.class')).should be_true
    File.exist?(File.join(classes_dir, 'jetpack/ssl/ReloadingSslContextFactory.class')).should be_true
    File.exist?(File.join(classes_dir, 'jetpack/ssl/VersionedFileResolver.class')).should be_true
  end

  it 'retrieved java jars' do
    pending 'These folders are not actually produced; either behavior or tests need to be fixed'
    lib_dir = 'spec/sample_projects/webapp_reloading/WEB-INF/lib'
    File.exist?(lib_dir).should be_true
    File.exist?(File.join(lib_dir, 'guava.jar')).should be_true
    File.exist?(File.join(lib_dir, 'joda-time.jar')).should be_true
    File.exist?(File.join(lib_dir, 'slf4j-api.jar')).should be_true
    File.exist?(File.join(lib_dir, 'slf4j-simple.jar')).should be_true
  end

  it 'runs' do
    pending "This test has incorrect expectations; netcat on the port would not produce 'Hello World'"
    pid_to_kill = run_app
    begin
      puts x!('nc localhost 19143').inspect
      x!('nc localhost 19143')[:stdout].should == 'Hello World'
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
