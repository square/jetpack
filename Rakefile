require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

task :default => :spec

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec => "spec:setup") do |t|
  t.pattern = "./spec/**/*_spec.rb"
end

namespace :spec do
  desc "Download required support files for running specs."
  task :setup do
    def local_mirror(url)
      local_path = "spec/local_mirror/" + File.basename(url)
      `curl #{url} > #{local_path}` unless File.exists?(local_path)
    end

    FileUtils.mkdir_p "spec/local_mirror" unless File.directory?("spec/local_mirror")

    local_mirror "http://jruby.org.s3.amazonaws.com/downloads/1.6.7/jruby-complete-1.6.7.jar"
    local_mirror "http://repo1.maven.org/maven2/org/mortbay/jetty/jetty-hightide/8.1.3.v20120416/jetty-hightide-8.1.3.v20120416.zip"
    local_mirror "http://repo1.maven.org/maven2/org/jruby/rack/jruby-rack/1.1.5/jruby-rack-1.1.5.jar"
  end
end
