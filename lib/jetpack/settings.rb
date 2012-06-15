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

    def initialize(project_dir, settings)
      settings = settings.inject({}) do |h, (k,v)|
        h[k.gsub("-", "_")] = v
        h
      end
      @keys = settings.keys.sort
      super(settings)
    end

    def jruby?
      respond_to?(:jruby)
    end

    def jetty?
      respond_to?(:jetty)
    end

    def rails?
      app_type == 'rails'
    end

    def inspect
      self.class.name + ":\n" + @keys.map{|k|"  #{k.ljust(20)} = #{send(k.to_sym)}"}.join("\n") + "\n"
    end
  end
end
