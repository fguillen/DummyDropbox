# require 'bundler/gem_tasks'

require 'rake'
require 'rake/testtask'
require 'bundler'

include Rake::DSL

Bundler::GemHelper.install_tasks

task :default => :test

Rake::TestTask.new do |t|
  t.libs << '.'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end