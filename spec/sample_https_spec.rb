require "spec_helper"
require "yaml"

describe "jetpack - sample https start" do
  let(:project) { "#{TEST_ROOT}/webapp" }
  let(:dest)    { "#{TEST_ROOT}/webapp_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/webapp", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} sample_https")
    replace_remote_references_with_local_mirror(src)
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end

  describe "https bootstrap" do
    it "places jetty config files and 'fake' keystore" do
      File.exists?("#{project}/config/jetpack_files/bin/ruby.erb").should == true
      File.exists?("#{project}/config/jetpack_files/WEB-INF/web.xml.erb").should == true
      File.exists?("#{project}/config/jetpack_files/vendor/jetty/etc/fake.jceks").should == true
    end
  end

  it "runs" do
    pid_to_kill = run_app(dest, check_port=8080)
    begin
      #HTTP XX443 - intended to be proxied to from something listening on 443
      x!("curl https://localhost:8443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

      #HTTP XXX80 - intended for internal health checking
      x!("curl http://localhost:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://#{Socket.gethostname}:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://127.0.0.1:8080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end
end
