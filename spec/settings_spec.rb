require 'spec_helper'
require 'jetpack/settings'

describe Jetpack::Settings do
  let(:project_dir) { File.join(File.dirname(__FILE__), 'sample_projects', 'webapp_filters') }
  let(:config_file) { File.join(project_dir, 'config', 'jetpack.yml') }

  describe 'initialize' do
    subject { described_class.new(project_dir, config) }
    let(:config) { {} }

    context 'defaults' do
      it 'sets app_root' do
        expect(subject.app_root).to eq(project_dir)
      end

      it 'sets app_user' do
        expect(subject.app_user).to eq(Etc.getpwuid(File.stat(subject.app_root).uid).name)
      end

      it 'sets java' do
        expect(subject.java).to eq('java')
      end

      it 'sets java_options' do
        expect(subject.java_options).to eq('-Xmx2048m')
      end

      it 'sets max_threads' do
        expect(subject.max_threads).to eq(50)
      end

      it 'sets ruby_version' do
        expect(subject.ruby_version).to eq(1.9)
      end

      it 'sets app_type' do
        expect(subject.app_type).to eq('rails')
      end

      it 'sets environment' do
        expect(subject.environment).to be_nil
      end

      it 'sets keystore_type' do
        expect(subject.keystore_type).to eq('PKCS12')
      end

      it 'sets keystore' do
        expect(subject.keystore).to be_nil
      end

      it 'sets keystore_password' do
        expect(subject.keystore_password).to be_nil
      end

      it 'sets bundle_without' do
        expect(subject.bundle_without).to match_array(%w(test development))
      end
    end

    context 'optional parameters' do
      ['https_port', 'http_port', 'jruby-rack', 'jetty', 'jetty_filters', 'jruby'].each do |key|
        it "sets #{key}" do
          value = rand
          config[key] = value
          settings_key = key.tr('-', '_')
          expect(subject.send(settings_key)).to eq(value)
        end
      end
    end

    it 'support arbitrary values' do
      config['s2s_port'] = 443
      expect(subject.s2s_port).to eq(443)
    end

    context 'with max_concurrent_connections set' do
      let(:config) { { 'max_concurrent_connections' => 20 } }

      it 'sets max threads to max_concurrent_connections' do
        expect(subject.max_threads).to eq(20)
      end
    end
  end

  describe 'load_from_project' do
    subject { described_class.load_from_project(project_dir) }

    it 'returns a Settings object' do
      expect(subject).to be_a(described_class)
    end

    it 'reads from the project config file' do
      config_yaml = YAML.load(File.read(config_file))
      expect(subject.http_port).to eq(config_yaml['http_port'])
    end
  end
end
