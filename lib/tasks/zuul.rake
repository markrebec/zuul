namespace :zuul do
  desc 'Visualize zuul roles and permissions'
  task :viz => :environment do
    require 'zuul_viz'
    ZuulViz.new.graph.output :png => "zuul_viz.png"
  end
end
