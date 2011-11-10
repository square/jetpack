require 'bundler'
Bundler::GemHelper.install_tasks

namespace :spec do
  desc "Download required support files for running specs."
  task :setup do
    def local_mirror(url)
      local_path = "spec/local_mirror/" + File.basename(url)
      `curl #{url} > #{local_path}` unless File.exists?(local_path)
    end

    local_mirror "http://jruby.org.s3.amazonaws.com/downloads/1.6.4/jruby-complete-1.6.4.jar"
    local_mirror "http://repo1.maven.org/maven2/org/mortbay/jetty/jetty-hightide/7.4.5.v20110725/jetty-hightide-7.4.5.v20110725.zip"
    local_mirror "http://repo1.maven.org/maven2/org/jruby/rack/jruby-rack/1.0.10/jruby-rack-1.0.10.jar"
  end
end
