require 'zuul_viz'
namespace :zuul do
  desc 'Visualize zuul roles and permissions'
  task :viz => :environment do
    ZuulViz.new.graph.output :png => "zuul_viz.png"
  end
end
