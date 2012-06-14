require "spec_helper"
require "yaml"

describe "jetpack - filters" do
  let(:project) { "#{TEST_ROOT}/webapp_filters" }
  let(:dest)    { "#{TEST_ROOT}/webapp_filters_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/webapp_filters", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} base")
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end

  it "runs" do
    pid_to_kill = run_app(dest, check_port=11080)
    begin
      x!("curl https://localhost:11443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl https://localhost:11443/hello?foo=bar --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl --head --request DEBUG https://localhost:11443/ --insecure")[:stdout].split("\n").first.strip.should == "HTTP/1.1 405 Method Not Allowed"

      x!("curl --head 'https://localhost:11443/<script>xss</script>.aspx' --insecure")[:stdout].split("\n").first.strip.should == "HTTP/1.1 400 Bad Request"

      x!("curl --head 'https://localhost:11443/?foo=<script>xss</script>.aspx' --insecure")[:stdout].split("\n").first.strip.should == "HTTP/1.1 400 Bad Request"

      x!("curl http://localhost:11080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://localhost:11080/hello?foo=bar")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://#{Socket.gethostname}:11080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl http://127.0.0.1:11080/hello")[:stdout].split("<br/>").first.strip.should == "Hello World"

      x!("curl --head --request DEBUG http://localhost:11080/")[:stdout].split("\n").first.strip.should == "HTTP/1.1 405 Method Not Allowed"

      x!("curl --head 'http://localhost:11080/<script>xss</script>.aspx'")[:stdout].split("\n").first.strip.should == "HTTP/1.1 400 Bad Request"

      x!("curl --head 'http://localhost:11080/?foo=<script>xss</script>.aspx'")[:stdout].split("\n").first.strip.should == "HTTP/1.1 400 Bad Request"

    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end
end
