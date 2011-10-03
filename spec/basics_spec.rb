require "spec_helper"

describe "preflight - basics" do
  before(:all) do 
    reset
    @result = x!("bin/preflight spec/sample_projects/no_dependencies")
  end
  after(:all) do 
    reset 
  end

  it "will put the jruby jar under vendor" do
    @result[:stderr].should == ""
    @result[:exitstatus].should == 0
    File.exists?("spec/sample_projects/no_dependencies/vendor/jruby.jar").should == true
  end

  it "creates a rake script" do
    @result[:stdout].should include("spec/sample_projects/no_dependencies/bin/rake\n")
    File.exists?("spec/sample_projects/no_dependencies/bin/rake").should == true
  end

  describe "creates a ruby script that" do
    it "allows you to execute using the jruby jar." do
      rake_result = x("spec/sample_projects/no_dependencies/bin/ruby -S rake project_info")
      rake_result[:stderr].should     == ""
      rake_result[:stdout].should include("Hi, I'm the no_dependencies project")
      rake_result[:exitstatus].should == 0
    end
  end

  describe "makes a rake script that" do
    it %{ - runs from any directory (properly cd's) 
          - the ruby used is indeed jruby
          - allows you to execute several tasks in a row
          - shows the trace of a rake failure
          - nails the GEM_PATH to within the jar so we don't go 'accidentally' loading gems and such from another ruby env, the result of which is insanity.
          
          Asserting all this in one test to optimize for test running time.} do
      absolute_script_path = File.expand_path("spec/sample_projects/no_dependencies/bin/rake project_info another_task load_path gem_path boom")
      rake_result = x("cd /tmp && #{absolute_script_path} project_info")

      rake_result[:stdout].should include("PWD=#{File.expand_path("spec/sample_projects/no_dependencies")}")
      rake_result[:stdout].should include("Hi, I'm the no_dependencies project")
      rake_result[:stdout].should include("RUBY_PLATFORM=java")
      rake_result[:stdout].should include("jruby.jar!/META-INF")
      rake_result[:stdout].should include("You ran another task")
                                         
      rake_result[:stderr].should include("BOOM")
      rake_result[:stderr].should include("xxx")
      rake_result[:stderr].should include("yyy")
      rake_result[:stderr].should include("zzz")
      rake_result[:exitstatus].should == 1

      load_path_elements = rake_result[:stdout].split("\n").select{|line|line =~ /^LP--/}
      load_path_elements.length >= 3
      load_path_elements.each do |element|
        element = element.sub("LP-- ", "")
        (element =~ /META-INF\/jruby\.home/ || element =~ /^\.$/).should >= 0
      end

      gem_path_elements = rake_result[:stdout].split("\n").select{|line|line =~ /^GP--/}
      gem_path_elements.length >= 2
      gem_path_elements.each do |element|
        element = element.sub("GP-- ", "")
        (element =~ /META-INF\/jruby\.home/ || element =~ /vendor\/bundler_gem/).should >= 0
      end
    end
  end  
end