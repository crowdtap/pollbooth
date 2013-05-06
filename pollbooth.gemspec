# encoding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)
$:.unshift File.expand_path("../../lib", __FILE__)

require 'pollbooth/version'

Gem::Specification.new do |s|
  s.name        = "pollbooth"
  s.version     = PollBooth::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kareem Kouddous"]
  s.email       = ["kareeknyc@gmail.com"]
  s.homepage    = "http://github.com/crowdtap/pollbooth"
  s.summary     = "Data cache refreshed regularly"
  s.description = "Data cache refreshed regularly"

  s.add_dependency "bigben",       ">= 0.0.1"

  s.files        = Dir["lib/**/*"]
  s.require_path = 'lib'
  s.has_rdoc     = false
end
