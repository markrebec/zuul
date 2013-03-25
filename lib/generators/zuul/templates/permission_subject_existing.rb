class AddZuulPermissionSubjectTo<%= table_name.camelize %> < ActiveRecord::Migration
  def self.up
    change_table(:<%= table_name %>) do |t|
<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>

      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps
    end

    add_index :<%= table_name %>, :<%= permission_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :<%= subject_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :context_type
    add_index :<%= table_name %>, :context_id
    add_index :<%= table_name %>, [:<%= permission_model.to_s.underscore.singularize %>_id, :<%= subject_model.to_s.underscore.singularize %>_id, :context_type, :context_id], :unique => true, :name => 'index_<%= table_name %>_on_<%= permission_model.to_s.underscore.singularize %>_and_<%= subject_model.to_s.underscore.singularize %>_and_context'
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
