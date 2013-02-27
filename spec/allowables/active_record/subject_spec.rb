require 'spec_helper'

describe "Allowables::ActiveRecord::Subject" do
  pending "should extend the model with RoleMethods"
  pending "should extend the model with PermissionMethods if permissions are enabled"

  describe "RoleMethods" do
    pending "should provide the model with has_many relationships for role_subjects and roles"
    
    describe "assign_role" do
      pending "should require a role object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_role to lookup the closest contextual match when a role slug is provided"
      pending "should use the role object when one is provided"
      pending "should fail and return false if the provided role is nil"
      pending "should fail and return false if the provided role cannot be used within the provided context"
      pending "should create the role_subjects record to link the subject to the provided role"
      pending "should fail and return false if the provided role is already assigned in the provided context"
    end

    describe "unassign_role" do
      pending "should require a role object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_role to lookup the closest contextual match when a role slug is provided"
      pending "should use the role object when one is provided"
      pending "should fail and return false if the provided role is nil"
      pending "should remove the role_subjects record that links the subject to the provided role"
      pending "should fail and return false if the provided role is not assigned in the provided context"
    end

    describe "has_role?" do
      pending "should require a role object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_role to lookup the closest contextual match when a role slug is provided"
      pending "should use the role object when one is provided"
      pending "should return false if the provided role is nil"
      pending "should look up the context chain for the assigned role"
      pending "should return false if the provided role is not assigned to the subject within the context chain"
    end

    describe "has_role_or_higher?" do
      pending "should require a role object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_role to lookup the closest contextual match when a role slug is provided"
      pending "should use the role object when one is provided"
      pending "should return false if the provided role is nil"
      pending "should return true if the subject has the provided role via has_role?"
      pending "should look up the context chain for an assigned role with a level >= that of the provided role"
      pending "should return false if a role with a level >= that of the provided role is not assigned to the subject within the context chain"
    end

    describe "highest_role" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return nil if no roles are assigned to the subject within the provided context"
      pending "should return the role with the highest level that is assigned to the subject within the provided context"
    end

    describe "roles_for" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return nil if no roles are assigned to the subject within the provided context"
      pending "should return all roles assigned to the subject within the provided context"
    end

    describe "roles_for?" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return false if no roles are assigned to the subject within the provided context"
      pending "should return true if any roles are assigned to the subject within the provided context"
    end
  end

  describe "PermissionMethods" do
    pending "should provide the model with has_many relationships for permission_subjects and permissions"
    
    describe "assign_permission" do
      pending "should require a permission object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_permission to lookup the closest contextual match when a permission slug is provided"
      pending "should use the permission object when one is provided"
      pending "should fail and return false if the provided permission is nil"
      pending "should fail and return false if the provided permission cannot be used within the provided context"
      pending "should create the permission_subjects record to link the subject to the provided permission"
      pending "should fail and return false if the provided permission is already assigned in the provided context"
    end

    describe "unassign_permission" do
      pending "should require a permission object or slug"
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should use target_permission to lookup the closest contextual match when a permission slug is provided"
      pending "should use the permission object when one is provided"
      pending "should fail and return false if the provided permission is nil"
      pending "should remove the permission_subjects record that links the subject to the provided permission"
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
      pending "should return false if the provided permission is not assigned to the subject within the context chain"
    end
    
    describe "permissions_for" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return nil if no permissions are assigned to the subject within the provided context"
      pending "should return all permissions assigned to the subject within the provided context"
    end

    describe "permissions_for?" do
      pending "should accept an optional context"
      pending "should use nil context when none is provided"
      pending "should return false if no permissions are assigned to the subject within the provided context"
      pending "should return true if any permissions are assigned to the subject within the provided context"
    end
  end
end
