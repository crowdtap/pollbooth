# encoding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)
$:.unshift File.expand_path("../../lib", __FILE__)

require 'async_callbacks/version'

Gem::Specification.new do |s|
  s.name        = "async_callbacks"
  s.version     = AsyncCallbacks::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kareem Kouddous"]
  s.email       = ["kareeknyc@gmail.com"]
  s.homepage    = "http://github.com/crowdtap/async_callbacks"
  s.summary     = "Asynchronous callbacks for Mongoid and Promiscuous"
  s.description = "Asynchronous callbacks for Mongoid and Promiscuous"

  s.files        = Dir["lib/**/*"]
  s.require_path = 'lib'
  s.has_rdoc     = false
end
