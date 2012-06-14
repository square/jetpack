require "spec_helper"
require "tmpdir"

describe "jetpack - bootstrap (base)" do
  let(:project) { "spec/sample_projects/no_dependencies" }

  before(:all) do
    reset
    x!("bin/jetpack-bootstrap #{project} base")[:exitstatus].should == 0
  end
  after(:all) do
    reset
  end

  it "recursively copies files from collections/base/ to project_root/config/jetpack_files" do
    Dir["#{project}/config/jetpack_files/**/*"].map{|f|f.sub(project + "/", "")}.should include("config/jetpack_files/bin/ruby.erb")
    Dir["#{project}/config/jetpack_files/**/*"].map{|f|f.sub(project + "/", "")}.should include("config/jetpack_files/bin/rake.erb")
  end
end
