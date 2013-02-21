require 'spec_helper'

describe "Allowables::ActiveRecord" do
  
  it "should provide ActiveRecord::Base with the acts_as_authorization_* and acts_as_authorization_*? methods" do
    ActiveRecord::Base.ancestors.include?(Allowables::ActiveRecord).should be_true
    [:subject, :role, :permission, :context].each do |type|
      ActiveRecord::Base.respond_to?("acts_as_authorization_#{type.to_s}").should be_true
      ActiveRecord::Base.respond_to?("acts_as_authorization_#{type.to_s}?").should be_true
    end
  end
  
  it "should provide ActiveRecord model instances with the acts_as_authorization_*? methods" do
    dummy = Dummy.new
    [:subject, :role, :permission, :context].each { |type| dummy.respond_to?("acts_as_authorization_#{type.to_s}?").should be_true }
  end
  
  context "acts_as_authorization_*?" do
    it "should return the same value from instances and their classes" do
      [User.new, Role.new, Permission.new, Context.new].each do |model|
        [:subject, :role, :permission, :context].each do |type|
          model.send("acts_as_authorization_#{type.to_s}?").should == model.class.send("acts_as_authorization_#{type.to_s}?")
        end
      end
    end
  end

  context "acts_as_authorization_subject" do
    pending "add specs"
  end

  context "acts_as_authorization_role" do
    pending "add specs"
  end

  context "acts_as_authorization_permission" do
    pending "add specs"
  end

  context "acts_as_authorization_context" do
    pending "add specs"
  end

end
