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
  
  create_table :permissions do |t|
    t.string :name
    t.string :slug
    t.string :context_type
    t.integer :context_id
  end

  create_table :role_users do |t|
    t.integer :user_id
    t.integer :role_id
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
  
  create_table :levels do |t|
    t.string :name
    t.string :slug
    t.integer :level
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :abilities do |t|
    t.string :name
    t.string :slug
    t.string :context_type
    t.integer :context_id
  end

  create_table :level_users do |t|
    t.integer :user_id
    t.integer :level_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :ability_users do |t|
    t.integer :user_id
    t.integer :ability_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :ability_levels do |t|
    t.integer :level_id
    t.integer :ability_id
    t.string :context_type
    t.integer :context_id
  end

  create_table :soldiers do |t|
    t.string :name
  end

  create_table :ranks do |t|
    t.string :name
    t.string :slug
    t.integer :level
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :skills do |t|
    t.string :name
    t.string :slug
    t.string :context_type
    t.integer :context_id
  end

  create_table :rank_soldiers do |t|
    t.integer :soldier_id
    t.integer :rank_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :skill_soldiers do |t|
    t.integer :soldier_id
    t.integer :skill_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :rank_skills do |t|
    t.integer :rank_id
    t.integer :skill_id
    t.string :context_type
    t.integer :context_id
  end

  create_table :weapons do |t|
    t.string :name
  end
  
  create_table :zuul_models_users do |t|
    t.string :name
  end

  create_table :zuul_models_roles do |t|
    t.string :name
    t.string :slug
    t.integer :level
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :zuul_models_permissions do |t|
    t.string :name
    t.string :slug
    t.string :context_type
    t.integer :context_id
  end

  create_table :zuul_models_role_users do |t|
    t.integer :user_id
    t.integer :role_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :zuul_models_permission_users do |t|
    t.integer :user_id
    t.integer :permission_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :zuul_models_permission_roles do |t|
    t.integer :role_id
    t.integer :permission_id
    t.string :context_type
    t.integer :context_id
  end
  
  create_table :zuul_models_contexts do |t|
    t.string :name
  end
end
