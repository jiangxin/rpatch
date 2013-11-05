# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rpatch/version'

Gem::Specification.new do |s|
  s.name        = "rpatch"
  s.version     = Rpatch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jiang Xin"]
  s.email       = ["worldhello.net@gmail.com"]
  s.description = "A patch utility support regexp in patchfile."
  s.summary     = "rpatch-#{Rpatch::VERSION}"
  s.homepage    = "http://github.com/jiangxin/rpatch"
  s.license       = "MIT"

  s.files            = `git ls-files -- lib/`.split($/)
  s.files           += %w[README.md LICENSE.txt]
  s.executables      = `git ls-files -- bin/`.split($/).map{ |f| File.basename(f) }
  s.test_files       = `git ls-files -- {spec,t}/*`.split($/)
  s.bindir           = 'bin'
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = ["lib"]

  s.required_ruby_version = '>= 1.8.7'

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.6"
end
