# frozen_string_literal: true

require_relative "lib/reissue/version"

Gem::Specification.new do |spec|
  spec.name = "reissue"
  spec.version = Reissue::VERSION
  spec.authors = ["Jim Gay"]
  spec.email = ["jim@saturnflyer.com"]

  spec.summary = "Keep your versions and changelogs up to date and prepared for release."
  spec.description = "This gem helps you to prepare for releases of new versions of your code."
  spec.homepage = "https://github.com/SOFware/reissue"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "Rakefile", "README.md", "CHANGELOG.md", "LICENSE.txt", "exe/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "keepachangelog"
end
