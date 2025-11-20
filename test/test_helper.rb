require "simplecov" if ENV["CI"]

# Disable chat_notifier plugin if environment variables are not set
# This prevents test failures when the plugin tries to send notifications
ENV["NOTIFY_APP_NAME"] ||= "reissue" unless ENV.key?("NOTIFY_APP_NAME")

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "reissue"
require "debug"
require "date"

require "minitest/autorun"
