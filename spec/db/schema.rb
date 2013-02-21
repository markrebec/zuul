ActiveRecord::Schema.define(:version => 0) do
  create_table :dummies do |t|
  end

  create_table :users do |t|
    t.string :name
  end

  create_table :roles do |t|
    t.string :name
    t.string :slug
    t.integer :level
    t.string :context_type
    t.integer :context_id
  end

  create_table :role_users do |t|
    t.integer :user_id
    t.integer :role_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :permissions do |t|
    t.string :name
    t.string :slug
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :permission_users do |t|
    t.integer :user_id
    t.integer :permission_id
    t.string :context_type
    t.integer :context_id
  end
  create_table :permission_roles do |t|
    t.integer :role_id
    t.integer :permission_id
    t.string :context_type
    t.integer :context_id
  end

  create_table :contexts do |t|
    t.string :name
  end
end
