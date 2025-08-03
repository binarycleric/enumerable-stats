# frozen_string_literal: true

require_relative "lib/enumerable_stats/version"

Gem::Specification.new do |s|
  s.name        = "enumerable-stats"
  s.version     = EnumerableStats::VERSION
  s.licenses    = ["MIT"]
  s.summary     = "Statistical Methods for Enumerable Collections"
  s.description = <<~DESC
    A Ruby gem that extends all Enumerable objects (Arrays, Ranges, Sets, etc.) with essential statistical methods.
    Provides mean, median, variance, and standard deviation calculations, along with robust outlier detection using the IQR method.
    Perfect for data analysis, performance monitoring, A/B testing, and cleaning datasets with extreme values.
    Zero dependencies and works seamlessly with any Ruby collection that includes Enumerable.
  DESC
  s.authors     = ["Jon Daniel"]
  s.email       = "binarycleric@gmail.com"
  s.homepage    = "https://github.com/binarycleric/enumerable-stats"
  s.metadata    = { "source_code_uri" => "https://github.com/binarycleric/enumerable-stats",
                    "github_repo" => "ssh://github.com/binarycleric/enumerable-stats",
                    "rubygems_mfa_required" => "true" }

  s.files = Dir.glob("lib/**/*", File::FNM_DOTMATCH)
  s.require_paths = %w[lib]

  s.required_ruby_version = ">= 3.1.0"
end
