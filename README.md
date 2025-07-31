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

### Comparison Methods

#### `#percentage_difference(other)`

Calculates the absolute percentage difference between this collection's mean and another value or collection's mean using the symmetric percentage difference formula.

```ruby
# Comparing two datasets
control_group = [85, 90, 88, 92, 85]    # mean = 88
test_group = [95, 98, 94, 96, 97]       # mean = 96

diff = control_group.percentage_difference(test_group)
puts diff  # => 8.7% (always positive)

# Comparing collection to single value
response_times = [120, 135, 125, 130, 140]  # mean = 130
target = 120

diff = response_times.percentage_difference(target)
puts diff  # => 8.0%

# Same result regardless of order
puts control_group.percentage_difference(test_group)  # => 8.7%
puts test_group.percentage_difference(control_group)  # => 8.7%
```

#### `#signed_percentage_difference(other)`

Calculates the signed percentage difference, preserving the direction of change. Positive values indicate this collection's mean is higher than the comparison; negative values indicate it's lower.

```ruby
# Performance monitoring - lower is better
baseline = [100, 110, 105, 115, 95]     # mean = 105ms
optimized = [85, 95, 90, 100, 80]       # mean = 90ms

improvement = optimized.signed_percentage_difference(baseline)
puts improvement  # => -15.38% (negative = improvement for response times)

regression = baseline.signed_percentage_difference(optimized)
puts regression   # => 15.38% (positive = regression)

# A/B testing - higher is better
control_conversions = [0.12, 0.11, 0.13, 0.12]    # mean = 0.12 (12%)
variant_conversions = [0.14, 0.13, 0.15, 0.14]    # mean = 0.14 (14%)

lift = variant_conversions.signed_percentage_difference(control_conversions)
puts lift  # => 15.38% (positive = improvement for conversion rates)
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

# Calculate performance lift
lift = variant_b.signed_percentage_difference(variant_a)
puts "Variant B lift: #{lift.round(1)}%" # => "Variant B lift: 34.8%"

# Check for outliers that might skew results
puts "A outliers: #{variant_a.outlier_stats[:outliers_removed]}"
puts "B outliers: #{variant_b.outlier_stats[:outliers_removed]}"
```

### Performance Comparison

```ruby
# Before and after optimization comparison
before_optimization = [150, 165, 155, 170, 160, 145, 175]  # API response times (ms)
after_optimization = [120, 125, 115, 130, 118, 122, 128]

puts "Before: #{before_optimization.mean.round(1)}ms ± #{before_optimization.standard_deviation.round(1)}ms"
puts "After:  #{after_optimization.mean.round(1)}ms ± #{after_optimization.standard_deviation.round(1)}ms"

# Calculate improvement (negative is good for response times)
improvement = after_optimization.signed_percentage_difference(before_optimization)
puts "Performance improvement: #{improvement.round(1)}%" # => "Performance improvement: -23.2%"

# Or use absolute difference for reporting
abs_diff = after_optimization.percentage_difference(before_optimization)
puts "Total performance change: #{abs_diff.round(1)}%" # => "Total performance change: 23.2%"
```

### Statistical Significance Testing

```ruby
# Comparing two datasets for meaningful differences
dataset_a = [45, 50, 48, 52, 49, 47, 51]
dataset_b = [48, 53, 50, 55, 52, 49, 54]

# Basic comparison
difference = dataset_b.signed_percentage_difference(dataset_a)
puts "Dataset B is #{difference.round(1)}% different from Dataset A"

# Check if difference is large enough to be meaningful
abs_difference = dataset_b.percentage_difference(dataset_a)
if abs_difference > 5.0  # 5% threshold
  puts "Difference of #{abs_difference.round(1)}% may be statistically significant"
else
  puts "Difference of #{abs_difference.round(1)}% is likely not significant"
end

# Consider variability
a_cv = (dataset_a.standard_deviation / dataset_a.mean) * 100  # Coefficient of variation
b_cv = (dataset_b.standard_deviation / dataset_b.mean) * 100

puts "Dataset A variability: #{a_cv.round(1)}%"
puts "Dataset B variability: #{b_cv.round(1)}%"
```

## Method Reference

| Method | Description | Returns | Notes |
|--------|-------------|---------|-------|
| `mean` | Arithmetic mean | Float | Works with any numeric collection |
| `median` | Middle value | Numeric or nil | Returns nil for empty collections |
| `variance` | Sample variance | Float | Uses n-1 denominator (sample variance) |
| `standard_deviation` | Sample standard deviation | Float | Square root of variance |
| `percentage_difference(other)` | Absolute percentage difference | Float | Always positive, symmetric comparison |
| `signed_percentage_difference(other)` | Signed percentage difference | Float | Preserves direction, useful for A/B tests |
| `remove_outliers(multiplier: 1.5)` | Remove outliers using IQR method | Array | Returns new array, original unchanged |
| `outlier_stats(multiplier: 1.5)` | Outlier removal statistics | Hash | Useful for monitoring and debugging |

## Requirements

- Ruby >= 3.1.0
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
