# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = true
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: :test

require_relative "lib/reissue/rake"

Reissue::Task.create :reissue do |task|
  task.updated_paths << "checksums"
  task.version_file = "lib/reissue/version.rb"
  task.commit = false
end

Rake::Task["release"].enhance do
  Rake::Task[:reissue].invoke("patch")
end
