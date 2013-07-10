require "spec_helper"
require "yaml"

describe "jetpack - reloading" do
  before(:all) do
    reset
    @result = x!("bin/jetpack spec/sample_projects/webapp_reloading")
  end

  after(:all) do
    reset
  end

  it "uses reloading SSL" do
    File.exists?("spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml").should be_true
    File.read("spec/sample_projects/webapp_reloading/vendor/jetty/jetty.xml").should include("class=\"jetpack.ssl.ReloadingSslContextFactory\"")
  end

  it "compiled java classes" do
    classes_dir = "spec/sample_projects/webapp_reloading/WEB-INF/classes"
    File.exists?(classes_dir).should be_true
    File.exists?(File.join(classes_dir, "jetpack/ssl/FileResolver.class")).should be_true
    File.exists?(File.join(classes_dir, "jetpack/ssl/ReloadingKeyManager.class")).should be_true
    File.exists?(File.join(classes_dir, "jetpack/ssl/ReloadingSslContextFactory.class")).should be_true
    File.exists?(File.join(classes_dir, "jetpack/ssl/VersionedFileResolver.class")).should be_true
  end

  it "retrieved java jars" do
    lib_dir = "spec/sample_projects/webapp_reloading/WEB-INF/lib"
    File.exists?(lib_dir).should be_true
    File.exists?(File.join(lib_dir, "guava.jar")).should be_true
    File.exists?(File.join(lib_dir, "joda-time.jar")).should be_true
    File.exists?(File.join(lib_dir, "slf4j-api.jar")).should be_true
    File.exists?(File.join(lib_dir, "slf4j-simple.jar")).should be_true
  end

  it "runs" do
    pid_to_kill = run_app
    begin
      puts x!("nc localhost 19143").inspect
      x!("nc localhost 19143")[:stdout].should == "Hello World"
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end

  def run_app
    jetty_pid = Process.spawn({'RAILS_ENV' => 'development'}, 'bin/launch', {:chdir => "spec/sample_projects/webapp_reloading"})
    start_time = Time.now
    loop do
      begin
        TCPSocket.open("localhost", 11443)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end
