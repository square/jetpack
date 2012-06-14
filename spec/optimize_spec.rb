require "spec_helper"
require "tmpdir"

describe "jetpack - optimize the run" do
  let(:src) { "#{TEST_ROOT}/optimize_src" }
  let(:dest) { "#{TEST_ROOT}/optimize_dest" }

  before do
    reset
    mkdir_p(TEST_ROOT)
    cp_r("spec/sample_projects/no_dependencies", src)
  end
  after do
    reset
  end

  it "performs a basic jetpack run" do
    x!("bin/jetpack #{src} #{dest}")[:exitstatus].should == 0
    File.exists?("#{dest}/vendor/jruby.jar").should == true
  end

  it "places a .jetpack-generated file that contains files that were not part of the source project" do
    x!("bin/jetpack #{src} #{dest}")
    File.exists?("#{dest}/.jetpack-generated").should == true
    File.read("#{dest}/.jetpack-generated").should ==
%{bin
bin/.rake_runner
bin/launch
bin/rake
bin/ruby
vendor
vendor/jruby.jar
}
  end
end
