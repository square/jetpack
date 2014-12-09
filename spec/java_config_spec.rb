require 'spec_helper'

describe 'jetpack - configurable java version' do
  before(:all) do
    reset
    @project = 'spec/sample_projects/java_config'
    @result = x!("bin/jetpack #{@project}")
  end

  after(:all) do
    reset
  end

  it 'uses the desired version of java' do
    expect(File.read("#{@project}/bin/ruby")).to include('/dev/null/java')
  end
end
