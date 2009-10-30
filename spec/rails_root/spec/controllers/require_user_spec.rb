require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ApplicationController
  include Zuul::RestrictAccess
  restrict_access
end

context "one role required for all actions" do
  class Stock1Controller < ApplicationController
    require_user :member
    def index; render :text => 'index'; end
    def show; render :text => 'show'; end
  end

  describe Stock1Controller do
    before do
      controller.stubs(:current_user).returns(@user = stub('user'))
    end

    it "denies someone without that role" do
      @user.stubs(:member?).returns(false)
      get :index
      response.should redirect_to('/')
    end
    it "allows someone with that role" do
      @user.stubs(:member?).returns(true)
      get :index
      response.body.should == 'index'
    end
    it "controls access to all actions in the controller" do
      @user.stubs(:member?).returns(false)
      get :index
      response.should redirect_to('/')
      get :show
      response.should redirect_to('/')
    end
  end
end

context "one role required for only one action" do
  class Stock2Controller < ApplicationController
    require_user :member, :only => :show
    def index; render :text => 'index'; end
    def show; render :text => 'show'; end
  end

  describe Stock2Controller do
    before do
      controller.stubs(:current_user).returns(@user = stub('user'))
    end

    it "denies someone without that role from the protected action" do
      @user.stubs(:member?).returns(false)
      get :show
      response.should redirect_to('/')
    end
    it "allows someone with that role into the protected action" do
      @user.stubs(:member?).returns(true)
      get :show
      response.body.should == 'show'
    end
    it "allows anyone into the unprotected action" do
      @user.stubs(:member?).returns(false)
      get :index
      response.body.should == 'index'
    end
  end
end

context "user with no specific role required for all actions" do
  class Stock3Controller < ApplicationController
    require_user
    def index; render :text => 'index'; end
    def show; render :text => 'show'; end
  end

  describe Stock3Controller do
    before do
      controller.stubs(:current_user).returns(@user = stub('user'))
    end

    it "denies access if there is no user" do
      controller.stubs(:current_user).returns(nil)
      get :show
      response.should redirect_to('/')
    end
    it "allows access to an admin user" do
      @user.stubs(:admin?).returns(true)
      get :show
      response.body.should == 'show'
    end
    it "allows access to a guest user" do
      @user.stubs(:guest?).returns(true)
      get :index
      response.body.should == 'index'
    end
  end
end

context "user with no specific role required for all but one action" do
  class Stock4Controller < ApplicationController
    require_user :except => :show
    def index; render :text => 'index'; end
    def show; render :text => 'show'; end
  end

  describe Stock4Controller do
    before do
      controller.stubs(:current_user).returns(@user = stub('user'))
    end

    it "denies access if there is no user" do
      controller.stubs(:current_user).returns(nil)
      get :index
      response.should redirect_to('/')
    end
    it "allows access to the unprotected action" do
      controller.stubs(:current_user).returns(nil)
      get :show
      response.body.should == 'show'
    end
  end
end

context "cannot access the actions if there is a user" do
  class Stock5Controller < ApplicationController
    require_no_user
    def index; render :text => 'index'; end
  end

  describe Stock5Controller do
    it "denies access if there is a user" do
      controller.stubs(:current_user).returns(@user = stub('user'))
      get :index
      response.should redirect_to('/')
    end
  end
end
