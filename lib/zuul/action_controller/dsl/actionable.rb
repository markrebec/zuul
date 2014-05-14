module Zuul
  module ActionController
    module DSL
      class Actionable < Base
        def all
          all_actions
        end

        def allow?(role_or_perm)
          match? role_or_perm
        end
        
        def deny?(role_or_perm)
          match? role_or_perm
        end
      end
    end
  end
end
