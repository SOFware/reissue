# frozen_string_literal: true

require "reissue/rake"

module Hoe::Reissue
  attr_accessor :reissue_version_file, :reissue_changelog_file,
    :reissue_version_limit, :reissue_version_redo_proc,
    :reissue_fragment, :reissue_clear_fragments,
    :reissue_retain_changelogs, :reissue_tag_pattern,
    :reissue_commit, :reissue_commit_finalize,
    :reissue_push_finalize, :reissue_push_reissue,
    :reissue_updated_paths

  def initialize_reissue
    self.reissue_version_file = "lib/#{name}/version.rb"
    self.reissue_changelog_file = "CHANGELOG.md"
    self.reissue_version_limit = 2
    self.reissue_version_redo_proc = nil
    self.reissue_fragment = nil
    self.reissue_clear_fragments = false
    self.reissue_retain_changelogs = false
    self.reissue_tag_pattern = nil
    self.reissue_commit = true
    self.reissue_commit_finalize = true
    self.reissue_push_finalize = false
    self.reissue_push_reissue = :branch
    self.reissue_updated_paths = []
  end

  def define_reissue_tasks
    config = {
      version_file: reissue_version_file,
      changelog_file: reissue_changelog_file,
      version_limit: reissue_version_limit,
      version_redo_proc: reissue_version_redo_proc,
      fragment: reissue_fragment,
      clear_fragments: reissue_clear_fragments,
      retain_changelogs: reissue_retain_changelogs,
      tag_pattern: reissue_tag_pattern,
      commit: reissue_commit,
      commit_finalize: reissue_commit_finalize,
      push_finalize: reissue_push_finalize,
      push_reissue: reissue_push_reissue,
      updated_paths: reissue_updated_paths
    }

    Reissue::Task.create :reissue do
      config.each { |attr, value| send(:"#{attr}=", value) }
    end

    Rake::Task.define_task(prerelease: ["reissue:bump", "reissue:finalize"])
    Rake::Task.define_task(postrelease: ["reissue"])
  end
end
