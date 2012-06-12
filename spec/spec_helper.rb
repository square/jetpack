require "fileutils"
require "open4"
require "net/http"
require "stringio"

include FileUtils


def x(cmd)
  stdout = StringIO.new
  stderr = StringIO.new
  result = Open4::spawn("sh -c \"#{cmd}\"", 'raise' => false, 'quiet' => true, 'stdout' => stdout, 'stderr' => stderr)
  exitstatus = result ? result.exitstatus : nil
  {:exitstatus => exitstatus, :stdout => stdout.string, :stderr => stderr.string}
end

def x!(cmd)
  result = x(cmd)
  raise "#{cmd} failed: #{result[:stderr]}" unless result[:exitstatus] == 0
  return result
end

def run_app(app, check_port, env={'RAILS_ENV' => 'development'})
  jetty_pid = Process.spawn(env, 'java', '-jar', 'start.jar', {:chdir => "#{app}/vendor/jetty"})
  start_time = Time.now
  loop do
    begin
      TCPSocket.open("localhost", check_port)
      return jetty_pid
    rescue Errno::ECONNREFUSED
      raise "it's taking too long to start the server, something might be wrong" if Time.now - start_time > 60
      sleep 0.1
    end
  end
end

real_tmp_dir = FileUtils.cd("/tmp") { FileUtils.pwd } #because on osx it's really /private/tmp
TEST_ROOT =  File.absolute_path("#{real_tmp_dir}/jetpack_test_root")

def reset
  FileUtils.rm_rf(TEST_ROOT)
end

RSpec.configure do |config|
  config.after(:all) do
    reset
  end
end
