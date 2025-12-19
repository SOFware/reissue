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

require_relative "lib/reissue/gem"

Reissue::Task.create :reissue do |task|
  task.version_file = "lib/reissue/version.rb"
  task.fragment = :git  # Use git trailers for changelog entries
  task.push_finalize = false
end
