# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deprecator/version'

Gem::Specification.new do |spec|
  spec.name          = "deprecator"
  spec.version       = Deprecator::VERSION
  spec.authors       = ["Philipp Fehre"]
  spec.email         = ["philipp.fehre@googlemail.com"]
  spec.description   = %q{Provide versioning for ruby objects and version migrations}
  spec.summary       = %q{Migrate persisted ruby objects between version by associating actions with version inconsitencies at load time}
  spec.homepage      = "http://github.com/sideshowcoder/deprecator"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
