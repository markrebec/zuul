require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Zuul do
  before do
    @user = User.new
  end

  it "knows its role" do
    @user.role = 'admin'
    @user.admin?.should be_true
  end

  it "returns its role as a symbol" do
    @user.role = 'admin'
    @user.role.should == :admin
  end

  it "assigns the role if it is in the list of valid roles" do
    @user.role = :member
    @user.role.should == :member
  end

  it "does not assign the role if it is not in the list of valid roles" do
    @user.role = 'admin'
    @user.role = :superuser
    @user.role.should == :admin
  end

  it "does not allow the role to be mass-assigned" do
    begin
      @user.update_attributes(:role => 'admin')
    rescue Exception => e
    ensure
      @user.role.should be_nil
    end
  end
end
