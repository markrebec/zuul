class AllowablesSubjectCreate<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    create_table(:<%= table_name %>) do |t|
<%= migration_data -%>

<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>

      t.timestamps
    end

    add_index :<%= table_name %>, :slug
    add_index :<%= table_name %>, :context_type
    add_index :<%= table_name %>, :context_id
    add_index :<%= table_name %>, [:slug, :context_type, :context_id],  :unique => true
  end
end
