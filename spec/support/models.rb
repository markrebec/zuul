class Dummy < ActiveRecord::Base
end

class User < ActiveRecord::Base
  attr_accessible :name
end

class Role < ActiveRecord::Base
  attr_accessible :name, :slug, :level, :context_type, :context_id
end

class RoleUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end

class Permission < ActiveRecord::Base
  attr_accessible :name, :slug, :context_type, :context_id
end

class PermissionUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :permission
end

class PermissionRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission
end

class Context < ActiveRecord::Base
end

class User < ActiveRecord::Base
  acts_as_authorization_subject
end
class Role < ActiveRecord::Base
  acts_as_authorization_role
end
class Permission < ActiveRecord::Base
  acts_as_authorization_permission
end
