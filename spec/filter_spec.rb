require "spec_helper"
require "yaml"

describe "jetpack - filters" do
  let(:dest) { "#{TEST_ROOT}/webapp_filters" }
  
  before(:all) do
    reset
    @result = x!("bin/jetpack spec/sample_projects/webapp_filters #{dest}")
  end
  after(:all) do
    reset
  end

  it "runs" do
    pid_to_kill = run_app
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

  def run_app
    jetty_pid = Process.spawn({'RAILS_ENV' => 'development'}, 'java', '-jar', 'start.jar', {:chdir => "#{dest}/vendor/jetty"})
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
