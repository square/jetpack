require "fileutils"
require "open4"
require "net/http"

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

unless File.directory?("spec/local_mirror")
  mkdir_p "spec/local_mirror"
  %w(jetty-hightide-7.4.5.v20110725.zip jruby-complete-1.6.4.jar jruby-rack-1.0.10.jar).each do |file|
    x! "curl --silent --show-error -o spec/local_mirror/#{file} http://mirrors.squareup.com/distfiles/#{file}"
  end
end

def reset
  Dir["spec/sample_projects/*/vendor/bundle"].each{|d|FileUtils.rm_rf(d)}
  Dir["spec/sample_projects/*/vendor/bundler_gem"].each{|d|FileUtils.rm_rf(d)}
  Dir["spec/sample_projects/*/*.jar"].each{|f|FileUtils.rm(f)}
  Dir["spec/sample_projects/*/.bundle"].each{|d|FileUtils.rm_rf(d)}
  Dir["spec/sample_projects/*/bin"].each{|d|FileUtils.rm_rf(d)}
  Dir["spec/sample_projects/*/vendor/jruby.jar"].each{|f|FileUtils.rm_f(f)}
  Dir["spec/sample_projects/*/vendor/jruby-rack.jar"].each{|f|FileUtils.rm_f(f)}
  Dir["spec/sample_projects/*/vendor/jetty"].each{|d|FileUtils.rm_rf(d)}
  Dir["spec/sample_projects/*/WEB-INF"].each{|d|FileUtils.rm_rf(d)}
end

RSpec.configure do |config|
  config.after(:all) do
    reset
  end
end