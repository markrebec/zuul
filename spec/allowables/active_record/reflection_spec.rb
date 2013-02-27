require 'spec_helper'

describe "Allowables::ActiveRecord::Reflection" do
  describe "set_authorization_class_names" do
    pending "should use the default authorization classes if none are provided"
    pending "should merge provided authorization classes with the defaults"
    pending "should redefine the join classes when custom classes are provided"
    pending "should not override join classes that are provided"
    pending "should define *_class and *_class_name methods for each authorization class"
  end
  
  describe "authorization_table_name" do
    pending "should use the Model.table_name to retrieve table names"
  end

  describe "*_table_name methods" do
    pending "should provide *_table_name methods for each of the authorization classes"
    pending "should return the correct table name for the model"
  end

  describe "*_foreign_key methods" do
    pending "should provide *_foreign_key methods for each of the core authorization classes (subjects, roles and permissions)"
    pending "should use the Model.foreign_key to retrieve keys"
  end

  context "Instance methods" do
    pending "should define all *_class, *_class_name, *_table_name and *_foreign_key methods and forward them to the class"
  end
end
