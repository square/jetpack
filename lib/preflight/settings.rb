require "ostruct"
require "yaml"
require "erb"

module Preflight
  class Settings < OpenStruct
    def self.load_from_project(project_dir)
      config_file = File.join(project_dir, "config/preflight.yml")
      raise("#{config_file} not found") unless File.exists?(config_file)
      yaml = YAML.load(ERB.new(File.read(config_file)).result)
      Settings.new(project_dir, yaml)
    end
    
    def initialize(project_dir, user_defined_options)
      contents = {}
      contents["app_root"] =      user_defined_options["app_root"]        || File.expand_path(project_dir)
      contents["app_user"] =      user_defined_options["app_user"]        || Etc.getpwuid(File.stat(contents["app_root"]).uid).name
      contents["java_options"] =  user_defined_options["java_options"]    || "-Xmx2048m"
      contents["https_port"] =    user_defined_options["https_port"]      || "4443"
      contents["http_port"] =     user_defined_options["http_port"]       || "4080"      
      contents["jruby_rack"] =    user_defined_options["jruby-rack"]      if user_defined_options.key?("jruby-rack")
      contents["jetty"] =         user_defined_options["jetty"]           if user_defined_options.key?("jetty")
      contents["jruby"] =         user_defined_options["jruby"]           if user_defined_options.key?("jruby")
      
      @keys = contents.keys.sort
      
      super(contents)
    end
    
    def jruby?
      respond_to?(:jruby)
    end

    def jetty?
      respond_to?(:jetty)
    end
    
    def inspect
      self.class.name + ":\n" + @keys.map{|k|"  #{k.ljust(20)} = #{send(k.to_sym)}"}.join("\n") + "\n"
    end
  end
end