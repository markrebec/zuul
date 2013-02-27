require 'spec_helper'

describe "Allowables::ActiveRecord::Role" do
  pending "should add validations for the core role fields"
  pending "should provide the model with has_many relationships for role_subjects and subjects"
  
  context "with permissions disabled" do
    pending "should not provide the model with has_many relationships for permission_roles and permissions"
    pending "should not provide the model with permissions methods"
  end

  context "with permissions enabled" do
    pending "should provide the model with has_many relationships for permission_roles and permissions"

    describe "assign_permission" do
      pending "should require a permission object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_permission to lookup the closest contextual match when a permission slug is provided"
      pending "should use the permission object when one is provided"
      pending "should fail and return false if the provided permission is nil"
      pending "should fail and return false if the provided permission cannot be used within the provided context"
      pending "should create the permission_roles record to link the role to the provided permission"
      pending "should fail and return false if the provided permission is already assigned in the provided context"
    end

    describe "unassign_permission" do
      pending "should require a permission object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_permission to lookup the closest contextual match when a permission slug is provided"
      pending "should use the permission object when one is provided"
      pending "should fail and return false if the provided permission is nil"
      pending "should remove the permission_roles record that links the role to the provided permission"
      pending "should fail and return false if the provided permission is not assigned in the provided context"
    end

    describe "has_permission?" do
      pending "should require a permission object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_permission to lookup the closest contextual match when a permission slug is provided"
      pending "should use the permission object when one is provided"
      pending "should return false if the provided permission is nil"
      pending "should look up the context chain for the assigned permission"
      pending "should return false if the provided permission is not assigned to the role within the context chain"
    end

    describe "permissions_for" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return nil if no permissions are assigned to the role within the provided context"
      pending "should return all permissions assigned to the role within the provided context"
    end

    describe "permissions_for?" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return false if no permissions are assigned to the role within the provided context"
      pending "should return true if any permissions are assigned to the role within the provided context"
    end
  end
end
