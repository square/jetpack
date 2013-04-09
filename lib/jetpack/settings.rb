require "ostruct"
require "yaml"
require "erb"

module Jetpack
  class Settings < OpenStruct
    def self.load_from_project(project_dir)
      config_file = File.join(project_dir, "config/jetpack.yml")
      raise("#{config_file} not found") unless File.exists?(config_file)
      yaml = YAML.load(ERB.new(File.read(config_file)).result)
      Settings.new(project_dir, yaml)
    end

    def initialize(project_dir, user_defined_options)
      contents                               = {}
      contents["app_root"]                   = user_defined_options["app_root"]                   || File.expand_path(project_dir)
      contents["app_user"]                   = user_defined_options["app_user"]                   || Etc.getpwuid(File.stat(contents["app_root"]).uid).name
      contents["java"]                       = user_defined_options["java"]                       || "java"
      contents["java_options"]               = user_defined_options["java_options"]               || "-Xmx2048m"
      contents["https_port"]                 = user_defined_options["https_port"]                 if user_defined_options.key?("https_port")
      contents["http_port"]                  = user_defined_options["http_port"]                  if user_defined_options.key?("http_port")
      contents["jruby_rack"]                 = user_defined_options["jruby-rack"]                 if user_defined_options.key?("jruby-rack")
      contents["jetty"]                      = user_defined_options["jetty"]                      if user_defined_options.key?("jetty")
      contents["jetty_filters"]              = user_defined_options["jetty_filters"]              if user_defined_options.key?("jetty_filters")
      contents["jruby"]                      = user_defined_options["jruby"]                      if user_defined_options.key?("jruby")
      contents["max_concurrent_connections"] = user_defined_options["max_concurrent_connections"] || 20
      contents["ruby_version"]               = user_defined_options["ruby_version"]               || "1.8"
      contents["app_type"]                   = user_defined_options["app_type"]                   || "rails"
      contents["environment"]                = user_defined_options["environment"]                || nil
      contents["keystore_type"]              = user_defined_options["keystore_type"]              || "PKCS12"
      contents["keystore"]                   = user_defined_options["keystore"]                   || nil
      contents["keystore_password"]          = user_defined_options["keystore_password"]          || nil

      @keys = contents.keys.sort

      super(contents)
    end

    def jruby?
      respond_to?(:jruby)
    end

    def jetty?
      respond_to?(:jetty)
    end

    def jetty_filters?
      respond_to?(:jetty_filters)
    end

    def rails?
      app_type == 'rails'
    end

    def jetty_pid_path
      File.join(app_root, "/vendor/jetty/run/jetty.pid")
    end

    def inspect
      self.class.name + ":\n" + @keys.map{|k|"  #{k.ljust(20)} = #{send(k.to_sym)}"}.join("\n") + "\n"
    end
  end
end
