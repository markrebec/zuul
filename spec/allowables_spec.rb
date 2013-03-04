require 'spec_helper'

describe "Allowables" do
  it "should possess a readable configuration object" do
    Allowables.configuration.should be_an_instance_of(Allowables::Configuration)
  end

  it "should forward calls to configure on to the configuration object" do
    Allowables.should respond_to(:configure)
    Allowables.configure do |config|
      config.should == Allowables.configuration
    end
  end

end
