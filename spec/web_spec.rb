require "spec_helper"
require "yaml"

describe "jetpack - web start" do
  let(:dest) { "#{TEST_ROOT}/no_dependencies" }

  before(:all) do
    reset
    @result = x!("bin/jetpack spec/sample_projects/webapp #{dest}")
  end
  after(:all) do
    reset
  end

  it "will unzip jetty under vendor if jetty.xml is present" do
    @result[:stderr].should == ""
    @result[:exitstatus].should == 0
    File.directory?("#{dest}/vendor/jetty").should == true
    File.directory?("#{dest}/vendor/jetty/lib").should == true
    File.exists?("#{dest}/vendor/jetty/start.jar").should == true
  end

  it "places config files" do
    File.exists?("#{dest}/WEB-INF/web.xml").should == true
    File.exists?("#{dest}/vendor/jetty/etc/jetty.xml").should == true
    File.exists?("#{dest}/vendor/jetty/etc/custom-project-specific-jetty.xml").should == true
    File.exists?("#{dest}/vendor/jetty/etc/template-from-project-jetty.xml").should == true
    File.exists?("#{dest}/vendor/jetty/etc/template-from-project-jetty.xml.erb").should == false
    File.read("#{dest}/vendor/jetty/etc/template-from-project-jetty.xml").should 
      include("<Arg>9443</Arg>")
    File.exists?("#{dest}/vendor/jetty/jetty-init").should == true
  end

  it "places a launch script, and includes java_options" do
    File.exists?("#{dest}/bin/launch").should == true
    File.read("#{dest}/bin/launch").should include("java -jar -Xmx256M")
    File.read("#{dest}/bin/launch").should include("start.jar")
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
