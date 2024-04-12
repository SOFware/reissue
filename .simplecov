SimpleCov.start do
  add_filter ["/test/", "/reissue/version.rb"]

  minimum_coverage 50
end
