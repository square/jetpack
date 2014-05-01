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

    local_mirror "http://jruby.org.s3.amazonaws.com/downloads/1.7.12/jruby-complete-1.7.12.jar"
    local_mirror "http://dist.codehaus.org/jetty/jetty-hightide-8.1.15/jetty-hightide-8.1.15.v20140411.zip"
    local_mirror "http://repository.codehaus.org/org/jruby/rack/jruby-rack/1.1.14/jruby-rack-1.1.14.jar"
  end
end
