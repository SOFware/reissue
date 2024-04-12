require "simplecov" if ENV["CI"]

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "reissue"
require "debug"

require "minitest/autorun"
