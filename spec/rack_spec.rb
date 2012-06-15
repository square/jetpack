require "spec_helper"
require "yaml"

describe "jetpack - web start for rack app" do
  let(:project) { "#{TEST_ROOT}/rack_19" }
  let(:dest)    { "#{TEST_ROOT}/rack_19_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/rack_19", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} sample_https")
    FileUtils.mv("#{project}/config/custom_jetpack.yml", "#{project}/config/jetpack.yml")
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end

  it "runs" do
    pid_to_kill = run_app(dest, check_port=10080, env={})
    begin
      #HTTP 4443 - intended to be proxied to from something listening on 443
      x!("curl https://localhost:10443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

      #HTTP 8080 - intended for internal health checking
      x!("curl http://localhost:10080/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end
end
