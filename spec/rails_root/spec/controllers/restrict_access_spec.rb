require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

context "specifying a custom 'access denied' flash message" do
  class ApplicationController1 < ActionController::Base
    include Zuul::RestrictAccess
    restrict_access :access_denied_message => "You shall not pass"
  end

  class StockController1 < ApplicationController1
    require_user
    def index; render :text => 'index'; end
  end

  describe StockController1 do
    it "uses the custom message" do
      controller.stubs(:current_user).returns(nil)
      get :index
      flash[:notice].should == "You shall not pass"
    end
  end
end

context "specifying a custom 'access denied' redirect path" do
  class ApplicationController2 < ActionController::Base
    include Zuul::RestrictAccess
    restrict_access :unauthorized_redirect_path => :signin_path
    def signin_path
      '/signup'
    end
  end

  class StockController2 < ApplicationController2
    require_user
    def index; render :text => 'index'; end
  end

  describe StockController2 do
    it "uses the custom message" do
      controller.stubs(:current_user).returns(nil)
      get :index
      response.should redirect_to('/signup')
    end
  end
end

context "specifying a custom 'cannot have a user' message" do
  class ApplicationController3 < ActionController::Base
    include Zuul::RestrictAccess
    restrict_access :require_no_user_message => "You can't do this with a user"
  end

  class StockController3 < ApplicationController3
    require_no_user
    def index; render :text => 'index'; end
  end

  describe StockController3 do
    it "uses the custom message" do
      controller.stubs(:current_user).returns(stub('user'))
      get :index
      flash[:notice].should == "You can't do this with a user"
    end
  end
end
