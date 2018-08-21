require 'fileutils'
require 'open4'
require 'net/http'
require 'stringio'

# Env vars like RUBYOPT get passed on to jruby.
# Cleanse the environment of these vars so that jruby is not affected.
ENV.delete_if { |k, _| k =~ /^(RUBY|BUNDLE|GEM|_JAVA_OPTIONS)/ }

# Set JAVA_HOME to Java 8. Jruby 1.7.x does not work with Java 9 and up.
if RbConfig::CONFIG['host_os'] =~ /darwin/
  ENV['JAVA_HOME'] = `/usr/libexec/java_home -v 1.8`.chomp
end

def x(cmd)
  stdout = StringIO.new
  stderr = StringIO.new
  result = Open4.spawn("sh -c \"#{cmd}\"", 'raise' => false, 'quiet' => true, 'stdout' => stdout, 'stderr' => stderr)
  exitstatus = result ? result.exitstatus : nil
  { :exitstatus => exitstatus, :stdout => stdout.string, :stderr => stderr.string }
end

def x!(cmd)
  result = x(cmd)
  raise "#{cmd} failed: #{result[:stderr]}" unless (result[:exitstatus]).zero?
  result
end

def reset
  Dir['spec/sample_projects/*/vendor/bundle'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/vendor/gems'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/*.jar'].each { |f| FileUtils.rm(f) }
  Dir['spec/sample_projects/*/.bundle'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/bin'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/etc'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/jetty'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/*jetty.xml'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/vendor/jruby.jar'].each { |f| FileUtils.rm_f(f) }
  Dir['spec/sample_projects/*/vendor/jruby-rack.jar'].each { |f| FileUtils.rm_f(f) }
  Dir['spec/sample_projects/*/vendor/jetty'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/vendor/cache'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/WEB-INF'].each { |d| FileUtils.rm_rf(d) }
  Dir['spec/sample_projects/*/log'].each { |d| FileUtils.rm_rf(d) }
end

RSpec.configure do |config|
  config.after(:all) do
    reset
  end
end
