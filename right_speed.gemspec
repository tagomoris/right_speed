# frozen_string_literal: true

require_relative "lib/right_speed/version"

Gem::Specification.new do |spec|
  spec.name          = "right_speed"
  spec.version       = RightSpeed::VERSION
  spec.authors       = ["Satoshi Moris Tagomori"]
  spec.email         = ["tagomoris@gmail.com"]

  spec.summary       = "HTTP server implementation using Ractor"
  spec.description   = "HTTP server, which provides traffic under the support of Ractor"
  spec.homepage      = "https://github.com/tagomoris/right_speed"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "webrick", "~> 1.7"
  spec.add_runtime_dependency "rack", "~> 1.3"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.1"
  spec.add_runtime_dependency "http_parser.rb", "~> 0.7"

  spec.add_development_dependency "test-unit"
end
