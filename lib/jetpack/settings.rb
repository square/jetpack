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
      defaults = {
        'app_root'                   => File.expand_path(project_dir),
        'java'                       => 'java',
        'java_options'               => '-Xmx2048m',
        'max_concurrent_connections' => 20,
        'ruby_version'               => 1.9,
        'app_type'                   => 'rails',
        'environment'                => nil,
        'keystore_type'              => 'PKCS12',
        'keystore'                   => nil,
        'keystore_password'          => nil,
        'truststore'                 => nil,
        'truststore_password'        => nil,
        'reload_keystore'            => false,
      }

      contents = defaults.merge(user_defined_options)

      contents['jruby_rack'] ||= contents['jruby-rack'] # backwards compatibility
      contents['app_user'] ||= Etc.getpwuid(File.stat(contents['app_root']).uid).name

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

    def reload_keystore?
      respond_to?(:reload_keystore)
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
