require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task :default => %i[spec rubocop]

desc 'Run all specs in spec directory'
RSpec::Core::RakeTask.new(:spec => 'spec:setup') do |t|
  t.pattern = './spec/**/*_spec.rb'
  t.rspec_opts = '--format documentation'
end

namespace :spec do
  desc 'Download required support files for running specs.'
  task :setup do
    def local_mirror(url)
      local_path = 'spec/local_mirror/' + File.basename(url)
      `curl #{url} > #{local_path}` unless File.exist?(local_path)
    end

    FileUtils.mkdir_p 'spec/local_mirror' unless File.directory?('spec/local_mirror')

    local_mirror 'https://repo1.maven.org/maven2/org/jruby/jruby-complete/1.7.25/jruby-complete-1.7.25.jar'
    local_mirror 'http://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.2.18.v20160721/jetty-distribution-9.2.18.v20160721.zip'
    local_mirror 'http://central.maven.org/maven2/org/jruby/rack/jruby-rack/1.1.20/jruby-rack-1.1.20.jar'
  end
end
