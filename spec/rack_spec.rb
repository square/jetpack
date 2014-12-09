require 'spec_helper'
require 'yaml'

describe 'jetpack - web start for rack app' do
  before(:all) do
    reset
    @result = x!('bin/jetpack spec/sample_projects/rack_19')
  end

  after(:all) do
    reset
  end

  it 'runs' do
    expect(ports_clear?(20443, 20080)).to be_truthy
    pid_to_kill = run_app('spec/sample_projects/rack_19')
    begin
      # HTTP 4443 - intended to be proxied to from something listening on 443
      expect(x!('curl https://localhost:20443/hello --insecure')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      # HTTP 9080 - intended for internal health checking
      expect(x!('curl http://localhost:20080/hello --insecure')[:stdout].split('<br/>').first.strip).to eq('Hello World')
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end

  def run_app(app)
    jetty_pid = Process.spawn({ 'RAILS_ENV' => 'development' }, 'java', '-jar', 'start.jar', :chdir => "#{app}/vendor/jetty")
    start_time = Time.now
    loop do
      begin
        TCPSocket.open('localhost', 20443)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end

  def ports_clear?(*ports)
    ports.all? do |port|
      `nc -z localhost #{port}`
      $?.exitstatus > 0
    end
  end
end
