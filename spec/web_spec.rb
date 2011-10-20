require "spec_helper"

describe "preflight - web start" do
  before(:all) do
    reset
    @result = x!("bin/preflight spec/sample_projects/webapp")
  end

  after(:all) do
    reset
    system("pkill -9 java")
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

  it "runs" do
    run_app
    
    #HTTP 4443 - intended to be proxied to from something listening on 443
    x!("curl https://localhost:4443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"
    
    #HTTP 9080 - intended for internal health checking
    x!("curl http://localhost:9080/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"
  end

  def run_app
    Thread.new do
      system("cd spec/sample_projects/webapp/vendor/jetty && RAILS_ENV=development java -jar start.jar") || raise("app start failed")
    end
    start_time = Time.now
    loop do
      begin
        TCPSocket.open("localhost", 4443)
        return
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end