require 'spec_helper'

describe 'jetpack - bundler and gems in 1.9 mode' do
  before(:all) do
    reset
    @project = 'has_gems_via_bundler_19'
    FileUtils.rm_rf("spec/sample_projects/#{@project}/vendor/bundle")
    FileUtils.rm_rf("spec/sample_projects/#{@project}/vendor/gems")
    x!("bin/jetpack spec/sample_projects/#{@project}")
  end

  after(:all) do
    FileUtils.rm_rf("spec/sample_projects/#{@project}/vendor/bundle")
    FileUtils.rm_rf("spec/sample_projects/#{@project}/vendor/gems")
  end

  describe 'gem installation' do
    it 'installed gems are available via Bundler.require' do
      rake_result = x("cd spec/sample_projects/#{@project} && " +
                      %(bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name'))
      expect(rake_result[:stderr]).to eq('')
      expect(rake_result[:stdout]).to eq("Spruz::Bijection\n")
      expect(rake_result[:exitstatus]).to eq(0)
    end
  end

  describe 'bin/rake' do
    it 'uses rake version specified in Gemfile' do
      rake_result = x("spec/sample_projects/#{@project}/bin/ruby bin/rake rake_version")
      expect(rake_result[:stdout].lines.to_a.last.chomp).to eq('0.9.2.2')
    end
  end
end
