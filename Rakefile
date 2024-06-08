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

desc "Prepare the code for work on a new version."
task :reissue, [:segment] => ["build:checksum"] do |task, args|
  require_relative "lib/reissue"
  segment = args[:segment] || "patch"
  Reissue.call(segment: segment, version_file: "lib/reissue/version.rb")
  `bundle install`
end

namespace :reissue do
  task :finalize, [:date] do |task, args|
    require_relative "lib/reissue"
    date = args[:date] || Time.now.strftime("%Y-%m-%d")
    Reissue.finalize(date, changelog_file: "CHANGELOG.md")
  end

  task :reformat do
    require_relative "lib/reissue"
    Reissue.reformat("CHANGELOG.md")
  end
end

Rake::Task["release"].enhance do
  Rake::Task[:reissue].invoke("patch")
end
