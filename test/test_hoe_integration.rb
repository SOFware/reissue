# frozen_string_literal: true

require "test_helper"
require "rake"
require "tmpdir"

# Hoe is normally a class defined by the hoe gem. We stub it here so the
# plugin module can be loaded without requiring the full hoe dependency.
module Hoe; end unless defined?(Hoe)

require "hoe/reissue"

class TestHoeIntegration < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_plugin_module_defines_expected_methods
    assert_method_defined Hoe::Reissue, :initialize_reissue
    assert_method_defined Hoe::Reissue, :define_reissue_tasks
  end

  def test_plugin_defines_reissue_tasks
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        plugin = Object.new
        plugin.extend(Hoe::Reissue)
        plugin.define_singleton_method(:name) { "my_gem" }
        plugin.initialize_reissue
        plugin.define_reissue_tasks

        assert Rake::Task.task_defined?("reissue")
        assert Rake::Task.task_defined?("reissue:finalize")
        assert Rake::Task.task_defined?("reissue:preview")
        assert Rake::Task.task_defined?("reissue:bump")
        assert Rake::Task.task_defined?("reissue:reformat")
      end
    end
  end

  def test_plugin_enhances_prerelease_task
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        Rake::Task.define_task(:prerelease)
        Rake::Task.define_task(:postrelease)

        plugin = Object.new
        plugin.extend(Hoe::Reissue)
        plugin.define_singleton_method(:name) { "my_gem" }
        plugin.initialize_reissue
        plugin.define_reissue_tasks

        prereqs = Rake::Task[:prerelease].prerequisites
        assert_includes prereqs, "reissue:bump"
        assert_includes prereqs, "reissue:finalize"
      end
    end
  end

  def test_plugin_enhances_postrelease_task
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        Rake::Task.define_task(:prerelease)
        Rake::Task.define_task(:postrelease)

        plugin = Object.new
        plugin.extend(Hoe::Reissue)
        plugin.define_singleton_method(:name) { "my_gem" }
        plugin.initialize_reissue
        plugin.define_reissue_tasks

        prereqs = Rake::Task[:postrelease].prerequisites
        assert_includes prereqs, "reissue"
      end
    end
  end

  def test_initialize_sets_defaults
    plugin = Object.new
    plugin.extend(Hoe::Reissue)
    plugin.define_singleton_method(:name) { "my_gem" }
    plugin.initialize_reissue

    assert_equal "lib/my_gem/version.rb", plugin.reissue_version_file
    assert_equal "CHANGELOG.md", plugin.reissue_changelog_file
    assert_equal 2, plugin.reissue_version_limit
    assert_nil plugin.reissue_version_redo_proc
    assert_nil plugin.reissue_fragment
    assert_equal false, plugin.reissue_clear_fragments
    assert_equal false, plugin.reissue_retain_changelogs
    assert_nil plugin.reissue_tag_pattern
    assert_equal true, plugin.reissue_commit
    assert_equal true, plugin.reissue_commit_finalize
    assert_equal false, plugin.reissue_push_finalize
    assert_equal :branch, plugin.reissue_push_reissue
    assert_equal [], plugin.reissue_updated_paths
  end

  def test_config_passed_through_to_task_instance
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        plugin = Object.new
        plugin.extend(Hoe::Reissue)
        plugin.define_singleton_method(:name) { "my_gem" }
        plugin.initialize_reissue
        plugin.reissue_fragment = :git
        plugin.reissue_commit = false
        plugin.reissue_version_limit = 5
        plugin.reissue_push_finalize = :branch
        plugin.reissue_updated_paths = ["checksums"]
        plugin.define_reissue_tasks

        task_instance = ObjectSpace.each_object(Reissue::Task).find { |t|
          t.version_file == "lib/my_gem/version.rb" && t.version_limit == 5
        }

        refute_nil task_instance, "Expected a Reissue::Task instance to be created"
        assert_equal :git, task_instance.fragment
        assert_equal false, task_instance.commit
        assert_equal 5, task_instance.version_limit
        assert_equal :branch, task_instance.push_finalize
        assert_includes task_instance.updated_paths, "checksums"
      end
    end
  end

  private

  def assert_method_defined(mod, method_name)
    assert mod.method_defined?(method_name) || mod.private_method_defined?(method_name),
      "Expected #{mod} to define #{method_name}"
  end

  def setup_git_repo(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    FileUtils.mkdir_p("lib/my_gem")
    File.write("lib/my_gem/version.rb", "VERSION = \"#{version}\"")
    File.write("CHANGELOG.md", <<~CHANGELOG)
      # Changelog

      ## [#{version}] - Unreleased

      ### Added

      - Initial release
    CHANGELOG

    system("git add .", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
    system("git branch -M main", out: File::NULL, err: File::NULL)
  end
end
