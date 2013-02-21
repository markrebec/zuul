require File.expand_path('spec/spec_helper')

describe "Allowables" do
  it "should test that all the active record stuff is working" do
    user = User.create(:name => "Test User")
    role = Role.create(:name => "Test Role", :slug => "test", :level => 1)
    user.assign_role(:test)
    user.has_role?(:test).should be_true
    user.remove_role(:test)
    user.has_role?(:test).should be_false
  end
end
