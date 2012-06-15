require "spec_helper"
require "tmpdir"

describe "jetpack - bootstrap (base)" do
  let(:project) { "#{TEST_ROOT}/no_dependencies" }

  before(:all) do
    reset
    FileUtils.cp_r("spec/sample_projects/no_dependencies", "#{TEST_ROOT}/")
    x!("bin/jetpack-bootstrap #{project} base")[:exitstatus].should == 0
    replace_remote_references_with_local_mirror(project)
  end
  after(:all) do
    reset
  end

  it "places jetpack.yml under a 'config' directory off of the project root" do
    File.exists?("#{project}/config/jetpack.yml").should == true
    File.exists?("#{project}/config/jetpack_files/jetpack.yml").should == false
    File.read("#{project}/config/jetpack.yml").should include("jruby:")
  end

  it "recursively copies files from collections/base/ to project_root/config/jetpack_files, with the exception of jetpack.yml" do
    Dir["#{project}/config/jetpack_files/**/*"].map{|f|f.sub(project + "/", "")}.should include("config/jetpack_files/bin/ruby.erb")
    Dir["#{project}/config/jetpack_files/**/*"].map{|f|f.sub(project + "/", "")}.should include("config/jetpack_files/bin/rake.erb")
  end
end
