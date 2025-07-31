# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "enumerable-stats"
  s.version     = "1.0.0"
  s.licenses    = ["MIT"]
  s.summary     = "Statistical Methods for Enumerable Collections"
  s.description = "Statistical Methods for Enumerable Collections"
  s.authors     = ["Jon Daniel"]
  s.email       = "binarycleric@gmail.com"
  s.homepage    = "https://github.com/binarycleric/enumerable-stats"
  s.metadata    = { "source_code_uri" => "https://github.com/binarycleric/enumerable-stats",
                    "rubygems_mfa_required" => "true" }

  s.files = Dir.glob("lib/**/*", File::FNM_DOTMATCH)
  s.require_paths = %w[lib]

  s.required_ruby_version = ">= 3.3.0"
end
