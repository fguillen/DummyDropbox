# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name        = "dummy_dropbox"
  s.version     = DummyDropbox::VERSION
  s.authors     = ["Fernando Guillen"]
  s.email       = ["fguillen.mail@gmail.com"]
  s.homepage    = "https://github.com/fguillen/DummyDropbox"
  s.summary     = "Dummy monkey patching for the dropbox ruby gem: 'dropbox'"
  s.description = "Dummy monkey patching for the dropbox ruby gem: 'dropbox'. You can test your Dropbox utility using a local folder to simulate your Dropbox folder."

  s.rubyforge_project = "DummyDropbox"
  
  s.add_development_dependency "bundler", ">= 1.0.0.rc.6"
  
  s.add_dependency "dropbox"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
