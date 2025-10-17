# frozen_string_literal: true

require "test_helper"

class TestBuildIntegration < Minitest::Test
  def test_gem_rb_enhances_build_with_bump_and_finalize
    # This test verifies that lib/reissue/gem.rb properly enhances
    # the build task with reissue:bump and reissue:finalize prerequisites
    assert_equal ["reissue:bump", "reissue:finalize"],
      File.read("lib/reissue/gem.rb").match(/Rake::Task\[:build\]\.enhance\(\[(.*?)\]\)/)[1].scan(/"([^"]+)"/).flatten
  end
end
