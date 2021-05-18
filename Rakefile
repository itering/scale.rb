require 'bundler/gem_tasks'
require "scale"
task default: :spec

desc 'Check types of a spec'
task :check_types do
  TypeRegistry.instance.load spec_name: 'darwinia'
end
