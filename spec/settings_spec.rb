require "spec_helper"
require "jetpack/settings"

describe Jetpack::Settings do
  let(:project_dir) { File.join(File.dirname(__FILE__), 'sample_projects', 'webapp_filters') }
  let(:config_file) { File.join(project_dir, 'config', 'jetpack.yml') }

  describe 'initialize' do
    subject { described_class.new(project_dir, config) }
    let(:config) { {} }

    context "defaults" do
      it "sets app_root" do
        subject.app_root.should == project_dir
      end

      it "sets app_user" do
        subject.app_user.should == Etc.getpwuid(File.stat(subject.app_root).uid).name
      end

      it "sets java" do
        subject.java.should == 'java'
      end

      it "sets java_options" do
        subject.java_options.should == '-Xmx2048m'
      end

      it "sets max_concurrent_connections" do
        subject.max_concurrent_connections.should == 20
      end

      it "sets ruby_version" do
        subject.ruby_version.should == '1.9'
      end

      it "sets app_type" do
        subject.app_type.should == 'rails'
      end

      it "sets environment" do
        subject.environment.should be_nil
      end

      it "sets keystore_type" do
        subject.keystore_type.should == 'PKCS12'
      end

      it "sets keystore" do
        subject.keystore.should be_nil
      end

      it "sets keystore_password" do
        subject.keystore_password.should be_nil
      end
    end

    context "optional parameters" do
      [ 'https_port', 'http_port', 'jruby-rack', 'jetty', 'jetty_filters', 'jruby' ].each do |key|
        it "sets #{key}" do
          value = rand()
          config[key] = value
          settings_key = key.gsub('-', '_')
          subject.send(settings_key).should == value
        end
      end
    end
  end

  describe 'load_from_project' do
    subject { described_class.load_from_project(project_dir) }

    it "returns a Settings object" do
      subject.should be_a(described_class)
    end

    it "reads from the project config file" do
      config_yaml = YAML.load(File.read(config_file))
      subject.http_port.should == config_yaml['http_port']
    end
  end
end
