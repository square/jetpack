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
    @result[:exitstatus].should == 0
    File.directory?('spec/sample_projects/webapp/vendor/jetty').should == true
    File.directory?('spec/sample_projects/webapp/vendor/jetty/lib').should == true
    File.exist?('spec/sample_projects/webapp/vendor/jetty/start.jar').should == true
  end

  it 'places the jetpack java code JAR' do
    File.exist?('spec/sample_projects/webapp/vendor/jetty/lib/ext/jetpack.jar').should == true
  end

  it 'places config files' do
    File.exist?('spec/sample_projects/webapp/WEB-INF/web.xml').should == true
    File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/jetty.xml').should == true
    File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/custom-project-specific-jetty.xml').should == true
    File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml').should == true
    File.exist?('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml.erb').should == false
    File.read('spec/sample_projects/webapp/vendor/jetty/etc/template-from-project-jetty.xml').should include('<Arg>9443</Arg>')
    File.exist?('spec/sample_projects/webapp/vendor/jetty/jetty-init').should == true
  end

  it 'places a launch script, and includes java_options' do
    File.exist?('spec/sample_projects/webapp/bin/launch').should == true
    File.read('spec/sample_projects/webapp/bin/launch').should include('java -jar -Xmx256M')
    File.read('spec/sample_projects/webapp/bin/launch').should include('start.jar')
  end

  it 'respects the maximun number of concurrent connections, http and https port' do
    jetty_xml = 'spec/sample_projects/webapp/vendor/jetty/etc/jetty.xml'
    settings = YAML.load_file('spec/sample_projects/webapp/config/jetpack.yml')
    max_threads_setting = /<Set name="maxThreads">#{settings["max_concurrent_connections"]}<\/Set>/

    File.exist?(jetty_xml).should == true

    jetty_xml_content = File.readlines(jetty_xml)
    jetty_xml_content.grep(max_threads_setting).should_not be_empty

    jetty_xml_content.grep(/<New class="org.eclipse.jetty.server.nio.SelectChannelConnector">/).should_not be_empty
    jetty_xml_content.grep(/<New class="org.eclipse.jetty.server.ssl.SslSelectChannelConnector">/).should_not be_empty
  end

  it 'runs' do
    pid_to_kill = run_app
    begin
      # HTTP XX443 - intended to be proxied to from something listening on 443
      x!('curl https://localhost:9443/hello --insecure')[:stdout].split('<br/>').first.strip.should == 'Hello World'

      # HTTP XXX80 - intended for internal health checking
      x!('curl http://localhost:9080/hello')[:stdout].split('<br/>').first.strip.should == 'Hello World'

      x!("curl http://#{Socket.gethostname}:9080/hello")[:stdout].split('<br/>').first.strip.should == 'Hello World'

      x!('curl http://127.0.0.1:9080/hello')[:stdout].split('<br/>').first.strip.should == 'Hello World'
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
