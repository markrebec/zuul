class ZuulViz

  def graph(*args)
    opts = {:subject_class => Zuul.configuration.subject_class.to_s.camelize.singularize.constantize}
    opts = opts.merge(args[0]) if args.length > 0
    subject_class = opts[:subject_class]

    g = GraphViz.new(:G, :type => :graph)
    g["compound"] = true
    g.edge["lhead"] = ""
    g.edge["ltail"] = ""
    #g["splines"] = "line"
    #g["rankdir"] = "LR"
    #g["nodesep"] = "2"
    #g["ranksep"] = "2"

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
          g.add_edges(graph_roles[permission_role.send(subject_class.auth_scope.role_foreign_key.to_sym)], graph_permissions[permission.id], :label => context_str(permission_role.context), :color => context_color(permission_role.context), :fontcolor => context_color(permission_role.context))
        end
        
        subject_class.auth_scope.permission_subject_class.where(subject_class.auth_scope.permission_foreign_key.to_sym => permission.id).group(:context_type, :context_id).each do |permission_subject|
          g.add_edges(graph_permissions[permission.id], ug.add_nodes("#{subject_class.auth_scope.permission_subject_class.where(subject_class.auth_scope.permission_foreign_key.to_sym => permission.id, :context_type => permission_subject.context_type, :context_id => permission_subject.context_id).count} #{subject_class.name.pluralize}"), :label => context_str(permission_subject.context), :color => context_color(permission_subject.context), :fontcolor => context_color(permission_subject.context))
        end
      end
    end
  
    g
  end

  def graph_subject(subject, *args)
    opts = {:subject_class => Zuul.configuration.subject_class.to_s.camelize.singularize.constantize}
    opts = opts.merge(args[0]) if args.length > 0
    if subject.is_a?(Integer)
      subject = opts[:subject_class].find(subject)
    else
      opts[:subject_class] = subject.class
    end
    
    g = GraphViz.new(:G, :type => :graph)
    g["compound"] = true
    g.edge["lhead"] = ""
    g.edge["ltail"] = ""
    #g["splines"] = "line"

    rg = g.add_graph("cluster0")
    rg["label"] = subject.auth_scope.role_class_name.pluralize
    pg = g.add_graph("cluster1")
    pg["label"] = subject.auth_scope.permission_class_name.pluralize
    
    subject_node = g.add_nodes("#{subject.class.name} #{subject.id}")
    
    subject.send(subject.auth_scope.role_subjects_table_name).each do |role_subject|
      role = role_subject.send(subject.auth_scope.role_class_name.underscore)
      role_node = rg.add_nodes(node_str(role))
      g.add_edges(subject_node, role_node, :label => context_str(role_subject.context), :color => context_color(role_subject.context), :fontcolor => context_color(role_subject.context))
      
      role.send(subject.auth_scope.permission_roles_table_name).each do |permission_role|
        permission = permission_role.send(subject.auth_scope.permission_class_name.underscore)
        g.add_edges(role_node, pg.add_nodes(node_str(permission)), :label => context_str(permission_role.context), :color => context_color(permission_role.context), :fontcolor => context_color(permission_role.context))
      end
    end
    
    subject.send(subject.auth_scope.permission_subjects_table_name).each do |permission_subject|
        permission = permission_subject.send(subject.auth_scope.permission_class_name.underscore)
        g.add_edges(subject_node, pg.add_nodes(node_str(permission)), :label => context_str(permission_subject.context), :color => context_color(permission_subject.context), :fontcolor => context_color(permission_subject.context))
    end

    g
  end

  def graph_role(role, *args)
    opts = {:role_class => Zuul.configuration.role_class.to_s.camelize.singularize.constantize}
    opts = opts.merge(args[0]) if args.length > 0
    if role.is_a?(Integer)
      role = opts[:role_class].find(role)
    else
      opts[:role_class] = role.class
    end
    
    g = GraphViz.new(:G, :type => :graph)
    g["compound"] = true
    g.edge["lhead"] = ""
    g.edge["ltail"] = ""
    #g["splines"] = "line"
    
    pg = g.add_graph("cluster0")
    pg["label"] = role.auth_scope.permission_class_name.pluralize
    ug = g.add_graph("cluster1")
    ug["label"] = role.auth_scope.subject_class_name.pluralize

    role_node = g.add_nodes(node_str(role))
      
    role.send(role.auth_scope.permission_roles_table_name).each do |permission_role|
      permission = permission_role.send(role.auth_scope.permission_class_name.underscore)
      g.add_edges(role_node, pg.add_nodes(node_str(permission)), :label => context_str(permission_role.context), :color => context_color(permission_role.context), :fontcolor => context_color(permission_role.context))
    end
    
    role.auth_scope.role_subject_class.where(role.auth_scope.role_foreign_key.to_sym => role.id).group(:context_type, :context_id).each do |role_subject|
      g.add_edges(role_node, ug.add_nodes("#{role.auth_scope.role_subject_class.where(role.auth_scope.role_foreign_key.to_sym => role.id, :context_type => role_subject.context_type, :context_id => role_subject.context_id).count} #{role.auth_scope.subject_class_name.pluralize}"), :label => context_str(role_subject.context), :color => context_color(role_subject.context), :fontcolor => context_color(role_subject.context))
    end

    g
  end

  def graph_permission(permission, *args)
    opts = {:permission_class => Zuul.configuration.permission_class.to_s.camelize.singularize.constantize}
    opts = opts.merge(args[0]) if args.length > 0
    if permission.is_a?(Integer)
      permission = opts[:permission_class].find(permission)
    else
      opts[:permission_class] = permission.class
    end
    
    g = GraphViz.new(:G, :type => :graph)
    g["compound"] = true
    g.edge["lhead"] = ""
    g.edge["ltail"] = ""
    #g["splines"] = "line"
    
    rg = g.add_graph("cluster0")
    rg["label"] = permission.auth_scope.role_class_name.pluralize
    ug = g.add_graph("cluster1")
    ug["label"] = permission.auth_scope.subject_class_name.pluralize

    permission_node = g.add_nodes(node_str(permission))
      
    permission.send(permission.auth_scope.permission_roles_table_name).each do |permission_role|
      role = permission_role.send(permission.auth_scope.role_class_name.underscore)
      g.add_edges(permission_node, rg.add_nodes(node_str(role)), :label => context_str(permission_role.context), :color => context_color(permission_role.context), :fontcolor => context_color(permission_role.context))
    end
    
    permission.auth_scope.permission_subject_class.where(permission.auth_scope.permission_foreign_key.to_sym => permission.id).group(:context_type, :context_id).each do |permission_subject|
      g.add_edges(permission_node, ug.add_nodes("#{permission.auth_scope.permission_subject_class.where(permission.auth_scope.permission_foreign_key.to_sym => permission.id, :context_type => permission_subject.context_type, :context_id => permission_subject.context_id).count} #{permission.auth_scope.subject_class_name.pluralize}"), :label => context_str(permission_subject.context), :color => context_color(permission_subject.context), :fontcolor => context_color(permission_subject.context))
    end

    g
  end

  protected

  def initialize
    # set some configuration args here to control colors, whether edges are labeled, etc.
    super
  end

  def context_color(context)
    if context.nil?
      "black"
    elsif context.id.nil?
      "#0000ff"
    else
      "#00aa00"
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
