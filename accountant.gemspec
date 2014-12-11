# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'accountant/version'

Gem::Specification.new do |spec|
  spec.name          = "accountant"
  spec.version       = Accountant::VERSION
  spec.authors       = ["Jason Cox"]
  spec.email         = ["jason@audioandpixels.com"]
  spec.summary       = %q{Financial accounts and reporting backed by double entry records.}
  spec.description   = %q{Give your app financial accounts, easily transfer money between them and generate reports all backed by auditable double entry records.}
  spec.homepage      = "https://github.com/audioandpixels/accountant"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'generator_spec'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pry'

  spec.add_dependency 'money-rails',           '~> 0.12.0'
  spec.add_dependency 'activerecord',          '>= 4.0.0'
  spec.add_dependency 'activesupport',         '>= 4.0.0'
  spec.add_dependency 'railties',              '>= 4.0.0'
end
