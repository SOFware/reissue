# frozen_string_literal: true

require "tempfile"

module GitRepoHelpers
  def init_git_repo
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)
  end

  def commit_everything(message)
    system("git add .", out: File::NULL, err: File::NULL)
    system("git commit -m '#{message}'", out: File::NULL, err: File::NULL)
  end

  def tag_version(version)
    system("git tag v#{version}", out: File::NULL, err: File::NULL)
  end

  def create_commit_with_trailer(subject, trailer)
    filename = "test_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system("git add #{filename}", out: File::NULL, err: File::NULL)

    Tempfile.create("commit_msg") do |f|
      f.write("#{subject}\n\n#{trailer}")
      f.flush
      system("git commit -F #{f.path}", out: File::NULL, err: File::NULL)
    end
  end
end
