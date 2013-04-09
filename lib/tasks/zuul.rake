require 'zuul_viz'
namespace :zuul do
  desc "Visualize a map of all Zuul roles, permissions and subjects -- optionally pass FORMAT=format and FILENAME=filename to control output"
  task :viz => :environment do |t|
    format = ENV["FORMAT"] || :png
    filename = ENV["FILENAME"] || "zuul_viz.#{format.to_s}"
    ZuulViz.new.graph.output format.to_sym => "#{Rails.root}/tmp/#{filename}"
    puts "Zuul graph saved to #{Rails.root}/tmp/#{filename}"
  end

  desc "Report statistics about all Zuul roles, permissions and subjects (Not Yet Implemented)"
  task :stats => :environment do |t|
    puts "Not Yet Implemented"
  end

  namespace :viz do
    desc "Visualize a map of assigned roles and permissions for a specific Zuul subject -- supports FORMAT and FILENAME parameters"
    task :subject, [:subject_id] => :environment do |t,args|
      if args.subject_id.nil?
        puts "Please provide a subject ID using the syntax `rake #{t.name}[subject_id]`"
        exit
      end
      format = ENV["FORMAT"] || :png
      filename = ENV["FILENAME"] || "zuul_viz_subject_#{args.subject_id}.#{format.to_s}"
      
      ZuulViz.new.graph_subject(args.subject_id.to_i).output format.to_sym => "#{Rails.root}/tmp/#{filename}"
      puts "Subject graph saved to #{Rails.root}/tmp/#{filename}"
    end

    desc "Visualize a map of subject assignments and permissions for a specific Zuul role -- supports FORMAT and FILENAME parameters"
    task :role, [:role_id] => :environment do |t,args|
      if args.role_id.nil?
        puts "Please provide a role ID using the syntax `rake #{t.name}[role_id]`"
        exit
      end
      format = ENV["FORMAT"] || :png
      filename = ENV["FILENAME"] || "zuul_viz_subject_#{args.role_id}.#{format.to_s}"
      
      ZuulViz.new.graph_role(args.role_id.to_i).output format.to_sym => "#{Rails.root}/tmp/#{filename}"
      puts "Role graph saved to #{Rails.root}/tmp/#{filename}"
    end
  
    desc "Visualize a map of role and subject assignments for a specific Zuul permission -- supports FORMAT and FILENAME parameters"
    task :permission, [:permission_id] => :environment do |t,args|
      if args.permission_id.nil?
        puts "Please provide a permission ID using the syntax `rake #{t.name}[permission_id]`"
        exit
      end
      format = ENV["FORMAT"] || :png
      filename = ENV["FILENAME"] || "zuul_viz_subject_#{args.permission_id}.#{format.to_s}"
      
      ZuulViz.new.graph_permission(args.permission_id.to_i).output format.to_sym => "#{Rails.root}/tmp/#{filename}"
      puts "Permission graph saved to #{Rails.root}/tmp/#{filename}"
    end
  end
end
