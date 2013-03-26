class ZuulViz

  def graph(*args)
    opts = {:subject_class => Zuul.configuration.subject_class.to_s.camelize.singularize.constantize}
    opts = opts.merge(args[0]) if args.length > 0
    subject_class = opts[:subject_class]

    g = GraphViz.new(:G, :type => :graph)
    g["compound"] = true
    g.edge["lhead"] = ""
    g.edge["ltail"] = ""
    g["rankdir"] = "LR"

    roles = subject_class.auth_scope.role_class.all
    raise "No roles to graph" if roles.length == 0

    ug = g.add_graph("cluster0")
    ug["label"] = "Assigned #{subject_class.name.pluralize}"
    rg = g.add_graph("cluster1")
    rg["label"] = subject_class.auth_scope.role_class_name.pluralize
    
    graph_roles = {}
    roles.each do |role|
      graph_roles[role.id] = rg.add_nodes(node_str(role))
    
      subject_class.auth_scope.role_subject_class.where(subject_class.auth_scope.role_foreign_key.to_sym => role.id).group(:context_type, :context_id).each do |role_subject|
        g.add_edges(graph_roles[role.id], ug.add_nodes("#{subject_class.auth_scope.role_subject_class.where(subject_class.auth_scope.role_foreign_key.to_sym => role.id, :context_type => role_subject.context_type, :context_id => role_subject.context_id).count} #{subject_class.name.pluralize}"), :label => context_str(role_subject.context), :color => context_color(role_subject.context), :fontcolor => context_color(role_subject.context))
      end
    end
    
    permissions = subject_class.auth_scope.permission_class.all
    if permissions.length > 0
      graph_permissions = {}
      pg = g.add_graph("cluster2")
      pg["label"] = subject_class.auth_scope.permission_class_name.pluralize
      
      permissions.each do |permission|
        graph_permissions[permission.id] = pg.add_nodes(node_str(permission))
        
        subject_class.auth_scope.permission_role_class.where(subject_class.auth_scope.permission_foreign_key.to_sym => permission.id).each do |permission_role|
          g.add_edges(graph_roles[permission_role.send(subject_class.auth_scope.role_foreign_key.to_sym)], graph_permissions[permission.id], :label => context_str(permission_role.context), :color => context_color(permission_role.context))
        end
        
        subject_class.auth_scope.permission_subject_class.where(subject_class.auth_scope.permission_foreign_key.to_sym => permission.id).group(:context_type, :context_id).each do |permission_subject|
          g.add_edges(graph_permissions[permission.id], ug.add_nodes("#{subject_class.auth_scope.permission_subject_class.where(subject_class.auth_scope.permission_foreign_key.to_sym => permission.id, :context_type => permission_subject.context_type, :context_id => permission_subject.context_id).count} #{subject_class.name.pluralize}"), :label => context_str(permission_subject.context), :color => context_color(permission_subject.context))
        end
      end
    end
  
    g
  end

  def graph_subject
    # draw a graph for the roles and permissions assigned to a specific subject
  end

  def graph_role
    # draw a graph of permissions and assigned users for a specific role
  end

  def graph_permission
    # draw a graph of assigned roles and assigned useres for a specific permission
  end

  protected

  def context_color(context)
    if context.nil?
      "black"
    elsif context.id.nil?
      "#000077"
    else
      "#0000ff"
    end
  end

  def context_str(context)
    if context.nil?
      "global"
    elsif context.id.nil?
      context.class_name
    else
      "@#{context.class_name.underscore}"
    end
  end

  def node_str(obj)
    "#{obj.slug}\n#{context_str(obj.context)}"
  end
end
