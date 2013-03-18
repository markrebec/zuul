require 'spec_helper'

describe "Zuul" do
  it "should possess a readable configuration object" do
    Zuul.configuration.should be_an_instance_of(Zuul::Configuration)
  end

  it "should forward calls to configure on to the configuration object" do
    Zuul.should respond_to(:configure)
    Zuul.configure do |config|
      config.should == Zuul.configuration
    end
  end

end
