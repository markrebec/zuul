# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require 'action_controller'
require 'action_controller/test_case'
require 'zuul'

class AssetsController < ActionController::Base
  include Zuul::AC
  restrict_access_to :admin
  def rescue_action(e) raise e end;
end

describe AssetsController do
  it "works" do
    get :index
  end
end
