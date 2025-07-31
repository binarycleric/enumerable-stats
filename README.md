# Enumerable Stats

[![CI](https://github.com/binarycleric/enumerable-stats/actions/workflows/ci.yml/badge.svg)](https://github.com/binarycleric/enumerable-stats/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3.0-ruby.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/enumerable-stats.svg)](https://badge.fury.io/rb/enumerable-stats)

A Ruby gem that extends Enumerable with statistical methods, making it easy to
calculate descriptive statistics and detect outliers in your data collections.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enumerable-stats'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install enumerable-stats
```

## Usage

Simply require the gem and all Enumerable objects (Arrays, Ranges, Sets, etc.)
will have the statistical methods available.

```ruby
require 'enumerable-stats'

data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
puts data.mean        # => 5.5
puts data.median      # => 5.5
puts data.variance    # => 9.17
```

## Statistical Methods

### Basic Statistics

#### `#mean`

Calculates the arithmetic mean (average) of the collection.

```ruby
[1, 2, 3, 4, 5].mean          # => 3.0
[10, 20, 30].mean             # => 20.0
[-1, 0, 1].mean               # => 0.0
```

#### `#median`

Calculates the median (middle value) of the collection.

```ruby
[1, 2, 3, 4, 5].median        # => 3 (odd number of elements)
[1, 2, 3, 4].median           # => 2.5 (even number of elements)
[5, 1, 3, 2, 4].median        # => 3 (automatically sorts)
[].median                     # => nil (empty collection)
```

#### `#variance`

Calculates the sample variance of the collection.

```ruby
[1, 2, 3, 4, 5].variance      # => 2.5
[5, 5, 5, 5].variance         # => 0.0 (no variation)
```

#### `#standard_deviation`

Calculates the sample standard deviation (square root of variance).

```ruby
[1, 2, 3, 4, 5].standard_deviation    # => 1.58
[5, 5, 5, 5].standard_deviation       # => 0.0
```

### Outlier Detection

#### `#remove_outliers(multiplier: 1.5)`

Removes outliers using the IQR (Interquartile Range) method. This is particularly
effective for performance data which often has extreme values due to network
issues, CPU scheduling, GC pauses, etc.

```ruby
# Basic usage
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 100]  # 100 is an outlier
clean_data = data.remove_outliers
# => [1, 2, 3, 4, 5, 6, 7, 8, 9] (outlier removed)

# Custom multiplier (more conservative = fewer outliers removed)
data.remove_outliers(multiplier: 2.0)    # Less aggressive
data.remove_outliers(multiplier: 1.0)    # More aggressive

# Performance data example
response_times = [45, 52, 48, 51, 49, 47, 53, 46, 2000, 48]  # 2000ms is an outlier
clean_times = response_times.remove_outliers
# => [45, 52, 48, 51, 49, 47, 53, 46, 48]
```

**Note:** Collections with fewer than 4 elements are returned unchanged since
quartile calculation requires at least 4 data points.

#### `#outlier_stats(multiplier: 1.5)`

Returns detailed statistics about outlier removal for debugging and logging purposes.

```ruby
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 100]
stats = data.outlier_stats

puts stats
# => {
#      original_count: 10,
#      filtered_count: 9,
#      outliers_removed: 1,
#      outlier_percentage: 10.0
#    }
```

## Working with Different Collection Types

The gem works with any Enumerable object:

```ruby
# Arrays
[1, 2, 3, 4, 5].mean                    # => 3.0

# Ranges
(1..10).median                          # => 5.5

# Sets
require 'set'
Set.new([1, 2, 3, 3, 4]).variance       # => 1.67 (duplicates ignored)

# Custom Enumerable objects
class DataSet
  include Enumerable

  def initialize(data)
    @data = data
  end

  def each(&block)
    @data.each(&block)
  end
end

dataset = DataSet.new([10, 20, 30, 40, 50])
dataset.standard_deviation              # => 15.81
```

## Real-World Examples

### Performance Monitoring

```ruby
# Analyzing API response times
response_times = [120, 145, 133, 128, 142, 136, 5000, 125, 139, 131]

puts "Original mean: #{response_times.mean.round(2)}ms"
# => "Original mean: 619.9ms" (skewed by the 5000ms outlier)

clean_times = response_times.remove_outliers
puts "Clean mean: #{clean_times.mean.round(2)}ms"
# => "Clean mean: 133.22ms" (more representative)

# Get outlier statistics for monitoring
stats = response_times.outlier_stats
puts "Removed #{stats[:outliers_removed]} outliers (#{stats[:outlier_percentage]}%)"
# => "Removed 1 outliers (10.0%)"
```

### Data Quality Analysis

```ruby
# Analyzing sensor readings
temperatures = [22.1, 22.3, 22.0, 22.2, 89.5, 22.1, 22.4]  # 89.5 is likely an error

puts "Raw data statistics:"
puts "  Mean: #{temperatures.mean.round(2)}°C"
puts "  Std Dev: #{temperatures.standard_deviation.round(2)}°C"

clean_temps = temperatures.remove_outliers
puts "\nCleaned data statistics:"
puts "  Mean: #{clean_temps.mean.round(2)}°C"
puts "  Std Dev: #{clean_temps.standard_deviation.round(2)}°C"
puts "  Sample size: #{clean_temps.size}/#{temperatures.size}"
```

### A/B Test Analysis

```ruby
# Conversion rates for two variants
variant_a = [0.12, 0.15, 0.11, 0.14, 0.13, 0.16, 0.12, 0.15]
variant_b = [0.18, 0.19, 0.17, 0.20, 0.18, 0.21, 0.19, 0.18]

puts "Variant A: #{(variant_a.mean * 100).round(1)}% ± #{(variant_a.standard_deviation * 100).round(1)}%"
puts "Variant B: #{(variant_b.mean * 100).round(1)}% ± #{(variant_b.standard_deviation * 100).round(1)}%"

# Check for outliers that might skew results
puts "A outliers: #{variant_a.outlier_stats[:outliers_removed]}"
puts "B outliers: #{variant_b.outlier_stats[:outliers_removed]}"
```

## Method Reference

| Method | Description | Returns | Notes |
|--------|-------------|---------|-------|
| `mean` | Arithmetic mean | Float | Works with any numeric collection |
| `median` | Middle value | Numeric or nil | Returns nil for empty collections |
| `variance` | Sample variance | Float | Uses n-1 denominator (sample variance) |
| `standard_deviation` | Sample standard deviation | Float | Square root of variance |
| `remove_outliers(multiplier: 1.5)` | Remove outliers using IQR method | Array | Returns new array, original unchanged |
| `outlier_stats(multiplier: 1.5)` | Outlier removal statistics | Hash | Useful for monitoring and debugging |

## Requirements

- Ruby >= 3.3.0
- No external dependencies

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec  # Run the tests
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/binarycleric/enumerable-stats>.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
