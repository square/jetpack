require 'spec_helper'
require 'yaml'

describe 'jetpack - filters' do
  before(:all) do
    reset
    @result = x!('bin/jetpack spec/sample_projects/webapp_filters')
  end

  after(:all) do
    reset
  end

  it 'runs' do
    pid_to_kill = run_app
    begin
      expect(x!('curl https://localhost:11443/hello --insecure')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl https://localhost:11443/hello?foo=bar --insecure')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl --head --request DEBUG https://localhost:11443/ --insecure')[:stdout].split("\n").first.strip).to eq('HTTP/1.1 405 Method Not Allowed')

      expect(x!("curl --head 'https://localhost:11443/<script>xss</script>.aspx' --insecure")[:stdout].split("\n").first.strip).to eq('HTTP/1.1 400 Bad Request')

      expect(x!("curl --head 'https://localhost:11443/?foo=<script>xss</script>.aspx' --insecure")[:stdout].split("\n").first.strip).to eq('HTTP/1.1 400 Bad Request')

      expect(x!('curl http://localhost:11080/hello')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl http://localhost:11080/hello?foo=bar')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!("curl http://#{Socket.gethostname}:11080/hello")[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl http://127.0.0.1:11080/hello')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl --head --request DEBUG http://localhost:11080/')[:stdout].split("\n").first.strip).to eq('HTTP/1.1 405 Method Not Allowed')

      expect(x!("curl --head 'http://localhost:11080/<script>xss</script>.aspx'")[:stdout].split("\n").first.strip).to eq('HTTP/1.1 400 Bad Request')

      expect(x!("curl --head 'http://localhost:11080/?foo=<script>xss</script>.aspx'")[:stdout].split("\n").first.strip).to eq('HTTP/1.1 400 Bad Request')
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end

  def run_app
    jetty_pid = Process.spawn({ 'RAILS_ENV' => 'development' }, 'java', '-jar', 'start.jar', :chdir => 'spec/sample_projects/webapp_filters/vendor/jetty')
    start_time = Time.now
    loop do
      begin
        TCPSocket.open('localhost', 11443)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end
