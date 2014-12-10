require 'spec_helper'

describe 'jetpack - bundler and gems' do

  before(:all) do
    reset
    rm_rf('spec/sample_projects/has_gems_via_bundler/vendor/bundle')
    rm_rf('spec/sample_projects/has_gems_via_bundler/vendor/gems')
    x!('bin/jetpack spec/sample_projects/has_gems_via_bundler')
  end

  after(:all) do
    rm_rf('spec/sample_projects/has_gems_via_bundler/vendor/bundle')
    rm_rf('spec/sample_projects/has_gems_via_bundler/vendor/gems')
  end

  describe 'presence of the library' do
    it 'installed bundler into vendor/gems.' do
      files = Dir['spec/sample_projects/has_gems_via_bundler/vendor/gems/**/*.rb'].to_a.map { |f| File.basename(f) }
      expect(files).to include('bundler.rb')
      expect(files).to include('dsl.rb')
    end

    it 'is not accidentally using bundler from another ruby environment.' do
      rake_result = x('spec/sample_projects/has_gems_via_bundler/bin/ruby bin/rake load_path_with_bundler')
      load_path_elements = rake_result[:stdout].split("\n").select { |line| line =~ /^--/ }
      expect(load_path_elements.length).to be >= 3
      invalid_load_path_elements =
        load_path_elements.reject do |element|
          element = element.sub('-- ', '')
          (element =~ /META-INF\/jruby\.home/ || element =~ /vendor\/gems/ || element =~ /^\.$/ || element =~ %r{vendor/bundle/})
        end
      expect(invalid_load_path_elements).to eq([])
    end

    it 'can be used from a script fed to jruby.' do
      rake_result = x(%(spec/sample_projects/has_gems_via_bundler/bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; puts Bundler::VERSION'))
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).not_to eq('')
      expect(rake_result[:exitstatus]).to eq(0)
    end
  end

  describe 'gem installation' do
    it 'installs gems into vendor/bundle' do
      files = Dir['spec/sample_projects/has_gems_via_bundler/vendor/bundle/**/*.rb'].to_a.map { |f| File.basename(f) }
      expect(files).to include('bijection.rb')
      expect(files).to include('spruz.rb')
      expect(files.length).to be > 20
    end

    it 'installed gems are available via normal require' do
      rake_result = x('cd spec/sample_projects/has_gems_via_bundler && ' +
                      %(bin/ruby -e 'require \\"rubygems\\"; require \\"bundler/setup\\"; require \\"spruz/bijection\\"; puts Spruz::Bijection.name'))
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).to eq("Spruz::Bijection\n")
      expect(rake_result[:exitstatus]).to eq(0)
    end

    it 'installed gems are available via Bundler.require' do
      rake_result = x('cd spec/sample_projects/has_gems_via_bundler && ' +
                      %(bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name'))
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).to eq("Spruz::Bijection\n")
      expect(rake_result[:exitstatus]).to eq(0)
    end

    it 'does not bundle groups specified in bundle_without' do
      rake_result = x('cd spec/sample_projects/has_gems_via_bundler && ' +
                          %(bin/ruby -e 'require \\"rubygems\\"; require \\"bundler/setup\\"; require \\"honor_codes\\"; puts HonorCodes.name'))
      expect(rake_result[:stderr]).to match(/LoadError: no such file to load -- honor_codes/)
      expect(rake_result[:exitstatus]).to be > 0
    end
  end

  describe 'bin/rake' do
    it 'uses rake version specified in Gemfile' do
      rake_result = x('spec/sample_projects/has_gems_via_bundler/bin/ruby bin/rake rake_version')
      expect(rake_result[:stdout].lines.to_a.last.chomp).to eq('0.9.2.2')
    end
  end

  describe 'Gemfile.lock that does not contain PLATFORM=java' do
    before do
      File.open('spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock/Gemfile.lock', 'w') do |f|
        f << %{GEM
  remote: http://rubygems.org/
  specs:
    rake (0.9.2.2)
    spruz (0.2.13)

PLATFORMS
  ruby

DEPENDENCIES
  rake (~> 0.9.2)
  spruz
}
      end
    end

    after do
      FileUtils.rm_f('spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock/Gemfile.lock')
    end

    it 'regenerates the Gemfile.lock and prints out a warning message' do
      expect(File.read('spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock/Gemfile.lock')).not_to include('java')
      jetpack_result = x('bin/jetpack spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock')
      expect(jetpack_result[:stderr].gsub("\n", '').squeeze(' ')).to include(%(
        WARNING: Your Gemfile.lock does not contain PLATFORM java.
        Automtically regenerating and overwriting Gemfile.lock using jruby
         - because otherwise, jruby-specific gems would not be installed by bundler.
        To make this message go away, you must re-generate your Gemfile.lock using jruby.
            ).gsub("\n", '').squeeze(' '))
      expect(jetpack_result[:exitstatus]).to eq(0)

      expect(File.read('spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock/Gemfile.lock')).to include('java')

      rake_result = x('cd spec/sample_projects/has_gems_via_bundler_bad_gemfile_lock && ' +
                      %(bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name'))
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).to eq("Spruz::Bijection\n")
      expect(rake_result[:exitstatus]).to eq(0)
    end
  end
end
