require "spec_helper"
require "yaml"

describe "jetpack - web start" do
  let(:project) { "#{TEST_ROOT}/webapp" }
  let(:dest)    { "#{TEST_ROOT}/webapp_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/webapp", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} http")
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end

  describe "http bootstrap" do
    it "places jetty config files" do
      File.exists?("#{project}/config/jetpack_files/WEB-INF/web.xml.erb").should == true
      File.exists?("#{project}/config/jetpack_files/vendor/jetty/etc/jetty.xml.erb").should == true
    end

    it "places a launch script, and includes java_options" do
      File.exists?("#{project}/config/jetpack_files/bin/launch.erb").should == true
    end
  end

  it "will unzip jetty under vendor if jetty.xml is present" do
    @result[:stderr].should == ""
    @result[:exitstatus].should == 0
    File.directory?("#{dest}/vendor/jetty").should == true
    File.directory?("#{dest}/vendor/jetty/lib").should == true
    File.exists?("#{dest}/vendor/jetty/start.jar").should == true
  end

  it "respects the maximun number of concurrent connections, http and https port" do
    jetty_xml = "#{dest}/vendor/jetty/etc/jetty.xml"
    settings = YAML.load_file("#{dest}/config/jetpack.yml")
    max_threads_setting = /<Set name="maxThreads">#{settings["max_concurrent_connections"]}<\/Set>/

    File.exists?(jetty_xml).should == true

    jetty_xml_content = File.readlines(jetty_xml)
    jetty_xml_content.grep(max_threads_setting).should_not be_empty

    jetty_xml_content.grep(/<New class="org.eclipse.jetty.server.nio.SelectChannelConnector">/).should_not be_empty
    jetty_xml_content.grep(/<New class="org.eclipse.jetty.server.ssl.SslSelectChannelConnector">/).should_not be_empty
  end

  it "runs" do
    pid_to_kill = run_app(dest, check_port=9080)
    begin
      #HTTP XX443 - intended to be proxied to from something listening on 443
      x!("curl https://localhost:9443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

      #HTTP XXX80 - intended for internal health checking
      x!("curl http://localhost:9080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://#{Socket.gethostname}:9080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://127.0.0.1:9080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end
end
