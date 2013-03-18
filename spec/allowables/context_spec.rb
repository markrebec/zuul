require 'spec_helper'

describe "Allowables::Context" do

  describe "parse" do
    it "should allow passing nil" do
      expect { Allowables::Context.parse(nil) }.to_not raise_exception
    end

    it "should allow passing a class" do
      expect { Allowables::Context.parse(Context) }.to_not raise_exception
    end

    it "should allow passing an instance" do
      context = Context.create(:name => "Test Context")
      expect { Allowables::Context.parse(context) }.to_not raise_exception
    end
    
    it "should allow passing another context" do
      expect { Allowables::Context.parse(Allowables::Context.new) }.to_not raise_exception
    end
    
    it "should allow passing a class_name and id" do
      expect { Allowables::Context.parse('Context', 1) }.to_not raise_exception
    end

    it "should return an Allowables::Context object with the context broken into it's two parts" do
      parsed = Allowables::Context.parse(nil)
      parsed.should be_an_instance_of(Allowables::Context)
    end
    
    it "should return a nil context context for nil" do
      parsed = Allowables::Context.parse(nil)
      parsed.class_name.should be_nil
      parsed.id.should be_nil
    end

    it "should return a context with class_name set to the class name for class context" do
      parsed = Allowables::Context.parse(Context)
      parsed.class_name.should == 'Context'
      parsed.id.should be_nil
    end
    
    it "should return a context with class_name and id set for an instance context" do
      context = Context.create(:name => "Test Context")
      parsed = Allowables::Context.parse(context)
      parsed.class_name.should == 'Context'
      parsed.id.should == context.id
    end
  end

  describe "#to_context" do
    it "should return nil for a nil context" do
      Allowables::Context.new.to_context.should be_nil
    end

    it "should return the class for a class context" do
      Allowables::Context.new('Context', nil).to_context.should == Context
    end

    it "should return the instance for an instance context" do
      obj = Context.create(:name => "Test Context")
      context = Allowables::Context.new('Context', obj.id).to_context
      context.should be_an_instance_of(Context)
      context.id.should == obj.id
    end
  end

  describe "#instance?" do
    it "should return false for a nil context" do
      Allowables::Context.new.instance?.should be_false
    end

    it "should return false for a class context" do
      Allowables::Context.new('Context', nil).instance?.should be_false
    end

    it "should return true for an instance context" do
      obj = Context.create(:name => "Test Context")
      Allowables::Context.new('Context', obj.id).instance?.should be_true
    end
  end

  describe "#class?" do
    it "should return false for a nil context" do
      Allowables::Context.new.class?.should be_false
    end

    it "should return true for a class context" do
      Allowables::Context.new('Context', nil).class?.should be_true
    end

    it "should return false for an instance context" do
      obj = Context.create(:name => "Test Context")
      Allowables::Context.new('Context', obj.id).class?.should be_false
    end
  end

  describe "#nil?" do
    it "should return true for a nil context" do
      Allowables::Context.new.nil?.should be_true
    end

    it "should return false for a class context" do
      Allowables::Context.new('Context', nil).nil?.should be_false
    end

    it "should return false for an instance context" do
      obj = Context.create(:name => "Test Context")
      Allowables::Context.new('Context', obj.id).nil?.should be_false
    end
  end

  describe "#type" do
    it "should return :nil for a nil context" do
      Allowables::Context.new.type.should == :nil
    end

    it "should return :class for a class context" do
      Allowables::Context.new('Context', nil).type.should == :class
    end

    it "should return :instance for an instance context" do
      obj = Context.create(:name => "Test Context")
      Allowables::Context.new('Context', obj.id).type.should == :instance
    end
  end
end
