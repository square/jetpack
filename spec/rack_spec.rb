require "spec_helper"
require "yaml"

describe "jetpack - web start for rack app" do
  before(:all) do
    reset
    @result = x!("bin/jetpack spec/sample_projects/rack_19")
  end

  after(:all) do
    reset
  end

  it "runs" do
    pid_to_kill = run_app("spec/sample_projects/rack_19")

    #HTTP 4443 - intended to be proxied to from something listening on 443
    x!("curl https://localhost:10443/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

    #HTTP 9080 - intended for internal health checking
    x!("curl http://localhost:10080/hello --insecure")[:stdout].split("<br/>").first.strip.should == "Hello World"

    system("kill -9 #{pid_to_kill}")
  end

  def run_app(app)
    jetty_pid = Process.spawn({'RAILS_ENV' => 'development'}, 'java', '-jar', 'start.jar', {:chdir => "#{app}/vendor/jetty"})
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
