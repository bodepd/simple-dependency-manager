$:.push File.expand_path("../lib", __FILE__)

require 'bodepd/simple/version'

Gem::Specification.new do |s|
  s.name = 'simple-dependency-manager'
  s.version = Bodepd::Simple::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Dan Bode']
  s.email = ['bodepd@gmail.com']
  s.homepage = 'https://github.com/bodepd/simple-dependency-manager'
  s.summary = 'Language agnostic dependency file'
  s.description = 'Simply grabs things from a Dependencies file and installs them. Simple.'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "thor", "~> 0.15"

  s.add_development_dependency "rspec", "~> 2.13"
end
