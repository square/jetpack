require 'spec_helper'
require 'yaml'

describe 'jetpack - web start' do
  before(:all) do
    reset
    @result = x!('bin/jetpack spec/sample_projects/webapp')
  end

  after(:all) do
    reset
  end

  it 'will unzip jetty under vendor if jetty.xml is present' do
    expect(@result[:exitstatus]).to eq(0)
    expect(File.directory?('spec/sample_projects/webapp/vendor/jetty')).to eq(true)
    expect(File.directory?('spec/sample_projects/webapp/vendor/jetty/lib')).to eq(true)
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/start.jar')).to eq(true)
  end

  it 'places the jetpack java code JAR' do
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/lib/ext/jetpack.jar')).to eq(true)
  end

  it 'places config files' do
    expect(File.exist?('spec/sample_projects/webapp/WEB-INF/web.xml')).to eq(true)
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/jetty.xml')).to eq(true)
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/custom-project-specific-jetty.xml')).to eq(true)
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml')).to eq(true)
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml.erb')).to eq(false)
    expect(File.read('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml')).to include('<Arg>9443</Arg>')
    expect(File.exist?('spec/sample_projects/webapp/vendor/jetty/jetty-init')).to eq(true)
  end

  it 'does not place extra config files' do
    expect(File.exist?('spec/sample_projects/webapp/custom-project-specific-jetty.xml')).to eq(false)
    expect(File.exist?('spec/sample_projects/webapp/etc/custom-project-specific-jetty.xml')).to eq(false)
    expect(File.exist?('spec/sample_projects/webapp/etc')).to eq(false)
  end

  it 'places a launch script, and includes java_options' do
    expect(File.exist?('spec/sample_projects/webapp/bin/launch')).to eq(true)
    expect(File.read('spec/sample_projects/webapp/bin/launch')).to include('java -jar -Xmx256M')
    expect(File.read('spec/sample_projects/webapp/bin/launch')).to include('start.jar')
  end

  it 'respects the maximum number of threads, http and https port' do
    start_ini = 'spec/sample_projects/webapp/vendor/jetty/start.ini'
    settings = YAML.load_file('spec/sample_projects/webapp/config/jetpack.yml')

    expect(File.exist?(start_ini)).to eq(true)

    start_ini_content = File.readlines(start_ini)
    expect(start_ini_content.grep(/threads.max=#{settings["max_threads"]}/)).not_to be_empty

    expect(start_ini_content.grep(/jetty.port=#{settings["http_port"]}/)).not_to be_empty
    expect(start_ini_content.grep(/jetty.secure.port=#{settings["https_port"]}/)).not_to be_empty
    expect(start_ini_content.grep(/https.port=#{settings["https_port"]}/)).not_to be_empty
  end

  it 'runs' do
    pid_to_kill = run_app
    begin
      # HTTP XX443 - intended to be proxied to from something listening on 443
      expect(x!('curl https://localhost:9443/hello --insecure')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      # HTTP XXX80 - intended for internal health checking
      expect(x!('curl http://localhost:9080/hello')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!("curl http://#{Socket.gethostname}:9080/hello")[:stdout].split('<br/>').first.strip).to eq('Hello World')

      expect(x!('curl http://127.0.0.1:9080/hello')[:stdout].split('<br/>').first.strip).to eq('Hello World')

      xss_output = x!("curl -i -X 'POST' -H 'Content-Type: application/x-www-form-urlencoded' --data-binary 'input=<script>alert(document.domain)</script>%' 'http://127.0.0.1:9080/hello'")[:stdout]

      expect(xss_output).not_to include('alert')
      expect(xss_output).not_to include('Rack::ShowStatus')
      expect(xss_output).to include('Content-Length: 0')
    ensure
      system("kill -9 #{pid_to_kill}")
    end
  end

  def run_app
    jetty_pid = Process.spawn({ 'RAILS_ENV' => 'development' }, 'java', '-jar', 'start.jar', :chdir => 'spec/sample_projects/webapp/vendor/jetty')
    start_time = Time.now
    loop do
      begin
        TCPSocket.open('localhost', 9443)
        return jetty_pid
      rescue Errno::ECONNREFUSED
        raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
        sleep 0.1
      end
    end
  end
end
