require "spec_helper"
require "yaml"

describe "jetpack - web start" do
  let(:project) { "#{TEST_ROOT}/webapp" }
  let(:dest)    { "#{TEST_ROOT}/webapp_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/webapp", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} sample_http")
    replace_remote_references_with_local_mirror(project)
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end

  describe "http bootstrap" do
    it "places jetty config files" do
      File.exists?("#{project}/config/jetpack_files/bin/ruby.erb").should == true
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

  it "runs" do
    pid_to_kill = run_app(dest, check_port=8080)
    begin
      #HTTP XXX80 - intended for internal health checking
      x!("curl http://localhost:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://#{Socket.gethostname}:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://127.0.0.1:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end
end
