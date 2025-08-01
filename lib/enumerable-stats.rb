# frozen_string_literal: true

require_relative "enumerable_stats/enumerable_ext"

module Enumerable
  include EnumerableStats::EnumerableExt
end
