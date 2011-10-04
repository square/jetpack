require "spec_helper"

describe "preflight - bundler and gems" do  

  before(:all) do
    reset
    rm_rf("spec/sample_projects/has_gems_via_bundler/vendor/bundle")
    rm_rf("spec/sample_projects/has_gems_via_bundler/vendor/bundler_gem")
    x!("bin/preflight spec/sample_projects/has_gems_via_bundler")
  end

  after(:all) do 
    rm_rf("spec/sample_projects/has_gems_via_bundler/vendor/bundle")
    rm_rf("spec/sample_projects/has_gems_via_bundler/vendor/bundler_gem")
  end
  
  describe "presence of the library" do
    it "installed bundler into vendor/bundler_gem." do
      files = Dir["spec/sample_projects/has_gems_via_bundler/vendor/bundler_gem/**/*.rb"].to_a.map{|f|File.basename(f)}
      files.should include("bundler.rb")
      files.should include("dsl.rb")
    end

    it "is not accidentally using bundler from another ruby environment." do
      rake_result = x("spec/sample_projects/has_gems_via_bundler/bin/rake load_path_with_bundler")
      load_path_elements = rake_result[:stdout].split("\n").select{|line|line =~ /^--/}
      load_path_elements.length.should >= 3
      load_path_elements.each do |element|
        element = element.sub("-- ", "")
        (element =~ /META-INF\/jruby\.home/ || element =~ /vendor\/bundler_gem/ || element =~ /^\.$/ || element =~ /vendor\/bundle\//).should >= 0
      end
    end

    it "can be used from a script fed to jruby." do
      rake_result = x(%{echo 'require \\"rubygems\\"; require \\"bundler\\"; puts Bundler::VERSION' | spec/sample_projects/has_gems_via_bundler/bin/ruby})
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should include("1.0.18")
      rake_result[:exitstatus].should == 0
    end
  end

  describe "gem installation" do
    it "installs gems into vendor/bundle" do
      files = Dir["spec/sample_projects/has_gems_via_bundler/vendor/bundle/**/*.rb"].to_a.map{|f|File.basename(f)}
      files.should include("bijection.rb")
      files.should include("spruz.rb")
      files.length.should > 20
    end

    it "installed gems are available via normal require" do
      rake_result = x("cd spec/sample_projects/has_gems_via_bundler && " +
                      %{echo 'require \\"rubygems\\"; require \\"bundler/setup\\"; require \\"spruz/bijection\\"; puts Spruz::Bijection.name' | bin/ruby})
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should     == "Spruz::Bijection\n"
      rake_result[:exitstatus].should == 0
    end

    it "installed gems are available via Bundler.require" do
      rake_result = x("cd spec/sample_projects/has_gems_via_bundler && " +
                      %{echo 'require \\"rubygems\\"; require \\"bundler\\"; Bundler.require; puts Spruz::Bijection.name' | bin/ruby})
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should     == "Spruz::Bijection\n"
      rake_result[:exitstatus].should == 0
    end
  end
end