require "spec_helper"

describe "jetpack - bundler and gems in 1.9 mode" do
  before(:all) do
    reset
    @project = 'has_gems_via_bundler_19'
    rm_rf("spec/sample_projects/#{@project}/vendor/bundle")
    rm_rf("spec/sample_projects/#{@project}/vendor/gems")
    x!("bin/jetpack spec/sample_projects/#{@project}")
  end

  after(:all) do
    rm_rf("spec/sample_projects/#{@project}/vendor/bundle")
    rm_rf("spec/sample_projects/#{@project}/vendor/gems")
  end

  describe "gem installation" do
    it "installed gems are available via Bundler.require" do
      rake_result = x("cd spec/sample_projects/#{@project} && " +
                      %{bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name'})
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should     == "Spruz::Bijection\n"
      rake_result[:exitstatus].should == 0
    end
  end

  describe "bin/rake" do
    it "uses rake version specified in Gemfile" do
      rake_result = x("spec/sample_projects/#{@project}/bin/rake rake_version")
      rake_result[:stdout].lines.to_a.last.chomp.should == "0.9.2.2"
    end
  end
end
