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

  it "does not build if no files that drive the jetpack run have changed" do
    x!("bin/jetpack #{src} #{dest}")[:exitstatus].should == 0
    File.exists?("#{dest}/vendor/jruby.jar").should == true
    File.exists?("#{dest}/.jetpack-generated").should == true

    #removing a file out of the desintation.
    #jetpack will not replace it because jetpack noop's
    rm("#{dest}/vendor/jruby.jar")

    second_run_result = x!("bin/jetpack #{src} #{dest}")
    second_run_result[:exitstatus].should == 0
    second_run_result[:stderr].should == "config/jetpack.yml is the same in both directories, skipping build.\n"
    File.exists?("#{dest}/vendor/jruby.jar").should == false
  end

  it "syncs project file changes from source to destination even if nothing jetpack-related has changed." +
     "jetpack build files should remain." do
    x!("bin/jetpack #{src} #{dest}")[:exitstatus].should == 0
    File.exists?("#{dest}/vendor/jruby.jar").should == true
    File.exists?("#{dest}/.jetpack-generated").should == true

    FileUtils.rm("#{src}/Rakefile")
    File.open("#{src}/newfile", "w"){|f|f<< "new"}

    #removing a file out of the desintation.
    #jetpack will not replace it because jetpack noop's
    rm("#{dest}/vendor/jruby.jar")

    x!("bin/jetpack #{src} #{dest}")[:exitstatus].should == 0
    File.exists?("#{dest}/vendor/jruby.jar").should == false
    File.exists?("#{dest}/newfile").should == true
    File.exists?("#{dest}/Rakefile").should == false
  end
end
