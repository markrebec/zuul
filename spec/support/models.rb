# Default Subject, Role, Permission and Context models
Object.send(:remove_const, :User) if defined?(User) # we do this to undefine the model and start fresh, without any of the authorization stuff applied by tests
class User < ActiveRecord::Base
  attr_accessible :name
end

Object.send(:remove_const, :Role) if defined?(Role)
class Role < ActiveRecord::Base
  attr_accessible :name, :slug, :level, :context_type, :context_id
end

Object.send(:remove_const, :Permission) if defined?(Permission)
class Permission < ActiveRecord::Base
  attr_accessible :name, :slug, :context_type, :context_id
end

Object.send(:remove_const, :Context) if defined?(Context)
class Context < ActiveRecord::Base
end

# Default association models
Object.send(:remove_const, :RoleUser) if defined?(RoleUser)
class RoleUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end

Object.send(:remove_const, :PermissionUser) if defined?(PermissionUser)
class PermissionUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :permission
end

Object.send(:remove_const, :PermissionRole) if defined?(PermissionRole)
class PermissionRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission
end

# Dummy model without any configuration for generic tests
Object.send(:remove_const, :Dummy) if defined?(Dummy)
class Dummy < ActiveRecord::Base
end


Object.send(:remove_const, :Soldier) if defined?(Soldier)
class Soldier < ActiveRecord::Base
  attr_accessible :name
end

Object.send(:remove_const, :Rank) if defined?(Rank)
class Rank < ActiveRecord::Base
  attr_accessible :name, :slug, :level, :context_type, :context_id
end

Object.send(:remove_const, :Skill) if defined?(Skill)
class Skill < ActiveRecord::Base
  attr_accessible :name, :slug, :context_type, :context_id
end

Object.send(:remove_const, :Weapon) if defined?(Weapon)
class Weapon < ActiveRecord::Base
end

Object.send(:remove_const, :RankSoldier) if defined?(RankSoldier)
class RankSoldier < ActiveRecord::Base
  belongs_to :soldier
  belongs_to :rank
end

Object.send(:remove_const, :SkillSoldier) if defined?(SkillSoldier)
class SkillSoldier < ActiveRecord::Base
  belongs_to :soldier
  belongs_to :skill
end

Object.send(:remove_const, :RankSkill) if defined?(RankSkill)
class RankSkill < ActiveRecord::Base
  belongs_to :rank
  belongs_to :skill
end
