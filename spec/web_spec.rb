require "spec_helper"
require "yaml"

describe "preflight - web start" do
  before(:all) do
    reset
    @result = x!("bin/preflight spec/sample_projects/webapp")
  end

  after(:all) do
    reset
  end

  it "will unzip jetty under vendor if jetty.xml is present" do
    @result[:stderr].should == ""
    @result[:exitstatus].should == 0
    File.directory?("spec/sample_projects/webapp/vendor/jetty").should == true
    File.directory?("spec/sample_projects/webapp/vendor/jetty/lib").should == true
    File.exists?("spec/sample_projects/webapp/vendor/jetty/start.jar").should == true
  end

  it "places config files" do
    File.exists?("spec/sample_projects/webapp/WEB-INF/web.xml").should == true
    File.exists?("spec/sample_projects/webapp/vendor/jetty/etc/jetty.xml").should == true
    File.exists?("spec/sample_projects/webapp/vendor/jetty/jetty-init").should == true
  end

  it "respects the maximun number of concurrent connections" do
    jetty_xml = "spec/sample_projects/webapp/vendor/jetty/etc/jetty.xml"
    settings = YAML.load_file("spec/sample_projects/webapp/config/preflight.yml")
    max_threads_setting = /<Set name="maxThreads">#{settings["max_concurrent_connections"]}<\/Set>/

    File.exists?(jetty_xml).should == true
    File.readlines(jetty_xml).grep(max_threads_setting).should_not be_empty
  end

  it "runs" do
    pid_to_kill = run_app

    #HTTP 4443 - intended to be proxied to from something listening on 443
    x!("curl https://localhost:10443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

    #HTTP 9080 - intended for internal health checking
    x!("curl http://localhost:10080/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

    system("kill -9 #{pid_to_kill}")
  end

  def run_app
    jetty_pid = Process.spawn({'RAILS_ENV' => 'development'}, 'java', '-jar', 'start.jar', {:chdir => "spec/sample_projects/webapp/vendor/jetty"})
    start_time = Time.now
    loop do
      begin
        TCPSocket.open("localhost", 10443)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end
