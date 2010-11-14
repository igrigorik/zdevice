# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zdevice/version"

Gem::Specification.new do |s|
  s.name        = "ZDevice"
  s.version     = Zdevice::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik"]
  s.email       = ["ilya@igvita.com"]
  s.homepage    = "http://github.com/igrigorik/zdevice"
  s.summary     = %q{ZDevice is a Ruby DSL for assembling arbitrary ZeroMQ routing devices, with support for the ZDCF configuration syntax.}
  s.description = s.summary

  s.rubyforge_project = "zdevice"
  s.add_dependency "ffi"
  s.add_dependency "ffi-rzmq"
  s.add_development_dependency "rspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
