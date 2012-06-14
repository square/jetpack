require "spec_helper"

describe "jetpack - bundler and gems in 1.9 mode" do
  let(:project) { "#{TEST_ROOT}/has_gems_via_bundler_19" }
  let(:dest)    { "#{TEST_ROOT}/has_gems_via_bundler_19_dest" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/has_gems_via_bundler_19", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} base")
    @result = x!("bin/jetpack #{project} #{dest}")
  end
  after(:all) do
    reset
  end
  
  describe "gem installation" do
    it "installed gems are available via Bundler.require" do
      rake_result = x("cd #{dest} && " +
                      %{bin/ruby -e 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name'})
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should     == "Spruz::Bijection\n"
      rake_result[:exitstatus].should == 0
    end
  end

  describe "bin/rake" do
    it "uses rake version specified in Gemfile" do
      rake_result = x("#{dest}/bin/rake rake_version")
      rake_result[:stdout].lines.to_a.last.chomp.should == "0.9.2.2"
    end
  end
end
