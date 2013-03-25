class ZuulRoleSubjectCreate<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    create_table(:<%= table_name %>) do |t|
<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>

      t.timestamps
    end

    add_index :<%= table_name %>, :<%= role_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :<%= subject_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :context_type
    add_index :<%= table_name %>, :context_id
    add_index :<%= table_name %>, [:<%= role_model.to_s.underscore.singularize %>_id, :<%= subject_model.to_s.underscore.singularize %>_id, :context_type, :context_id], :unique => true, :name => 'index_<%= table_name %>_on_<%= role_model.to_s.underscore.singularize %>_and_<%= subject_model.to_s.underscore.singularize %>_and_context'
  end
end
