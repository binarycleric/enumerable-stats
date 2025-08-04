# Enumerable Stats

[![CI](https://github.com/binarycleric/enumerable-stats/actions/workflows/ci.yml/badge.svg)](https://github.com/binarycleric/enumerable-stats/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1.0-ruby.svg)](https://www.ruby-lang.org/)
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

#### `#percentile(percentile)`

Calculates the specified percentile of the collection using linear interpolation. This is equivalent to the "linear" method used by many statistical software packages (R-7/Excel method).

```ruby
# Basic percentile calculations
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

data.percentile(0)     # => 1 (minimum value)
data.percentile(25)    # => 3.25 (first quartile)
data.percentile(50)    # => 5.5 (median)
data.percentile(75)    # => 7.75 (third quartile)
data.percentile(100)   # => 10 (maximum value)

# Performance monitoring percentiles
response_times = [45, 52, 48, 51, 49, 47, 53, 46, 50, 54]

p50 = response_times.percentile(50)   # => 49.5ms (median response time)
p95 = response_times.percentile(95)   # => 53.8ms (95th percentile - outlier threshold)
p99 = response_times.percentile(99)   # => 53.96ms (99th percentile - extreme outliers)

puts "50% of requests complete within #{p50}ms"
puts "95% of requests complete within #{p95}ms"
puts "99% of requests complete within #{p99}ms"

# Works with any numeric data
scores = [78, 85, 92, 88, 76, 94, 82, 89, 91, 87]
puts "Top 10% threshold: #{scores.percentile(90)}"  # => 92.4
puts "Bottom 25% cutoff: #{scores.percentile(25)}"  # => 80.5
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

### Statistical Testing Methods

#### `#t_value(other)`

Calculates the t-statistic for comparing the means of two samples using Welch's t-test formula, which doesn't assume equal variances. Used in hypothesis testing to determine if two groups have significantly different means.

```ruby
# A/B test: comparing conversion rates
control_group = [0.12, 0.11, 0.13, 0.12, 0.14, 0.11, 0.12]     # mean ≈ 0.121
test_group = [0.15, 0.16, 0.14, 0.17, 0.15, 0.18, 0.16]        # mean ≈ 0.157

t_stat = control_group.t_value(test_group)
puts t_stat  # => -4.2 (negative means test_group > control_group)

# Performance comparison: API response times
baseline = [100, 120, 110, 105, 115, 108, 112]   # Slower responses
optimized = [85, 95, 90, 88, 92, 87, 89]         # Faster responses

t_stat = baseline.t_value(optimized)
puts t_stat  # => 5.8 (positive means baseline > optimized, which is bad for response times)

# The larger the absolute t-value, the more significant the difference
puts "Significant difference!" if t_stat.abs > 2.0  # Rule of thumb threshold
```

#### `#degrees_of_freedom(other)`

Calculates the degrees of freedom for statistical testing using Welch's formula. This accounts for different sample sizes and variances between groups and is used alongside the t-statistic for hypothesis testing.

```ruby
# Calculate degrees of freedom for the same samples
control = [0.12, 0.11, 0.13, 0.12, 0.14, 0.11, 0.12]
test = [0.15, 0.16, 0.14, 0.17, 0.15, 0.18, 0.16]

df = control.degrees_of_freedom(test)
puts df  # => ~11.8 (used to look up critical t-values in statistical tables)

# With equal variances, approaches n1 + n2 - 2
equal_var_a = [10, 11, 12, 13, 14]  # variance = 2.5
equal_var_b = [15, 16, 17, 18, 19]  # variance = 2.5
df_equal = equal_var_a.degrees_of_freedom(equal_var_b)
puts df_equal  # => ~8.0 (close to 5 + 5 - 2 = 8)

# With unequal variances, will be less than pooled degrees of freedom
unequal_a = [10, 10, 10, 10, 10]        # very low variance
unequal_b = [5, 15, 8, 20, 12, 25, 18]  # high variance
df_unequal = unequal_a.degrees_of_freedom(unequal_b)
puts df_unequal  # => ~6.2 (much less than 5 + 7 - 2 = 10)
```

#### `#greater_than?(other, alpha: 0.05)`

Tests if this collection's mean is significantly greater than another collection's mean using a one-tailed Student's t-test. Returns `true` if the difference is statistically significant at the specified alpha level.

```ruby
# A/B testing: is the new feature performing better?
control_conversion = [0.118, 0.124, 0.116, 0.121, 0.119, 0.122, 0.117] # ~12.0% avg
variant_conversion = [0.135, 0.142, 0.138, 0.144, 0.140, 0.136, 0.139] # ~13.9% avg

# Is the variant significantly better than control?
puts variant_conversion.greater_than?(control_conversion)  # => true (significant improvement)
puts control_conversion.greater_than?(variant_conversion)  # => false

# Performance testing: is new optimization significantly faster?
old_response_times = [145, 152, 148, 159, 143, 156, 147, 151, 149, 154] # ~150ms avg
new_response_times = [125, 128, 122, 131, 124, 129, 126, 130, 123, 127] # ~126ms avg

# Are old times significantly greater (worse) than new times?
puts old_response_times.greater_than?(new_response_times)  # => true (significant improvement)

# Custom significance level for more conservative testing
puts variant_conversion.greater_than?(control_conversion, alpha: 0.01)  # 99% confidence
puts variant_conversion.greater_than?(control_conversion, alpha: 0.10)  # 90% confidence

# Check with similar groups (should be false)
similar_a = [10, 11, 12, 13, 14]
similar_b = [10.5, 11.5, 12.5, 13.5, 14.5]
puts similar_b.greater_than?(similar_a)  # => false (difference not significant)
```

#### `#less_than?(other, alpha: 0.05)`

Tests if this collection's mean is significantly less than another collection's mean using a one-tailed Student's t-test. Returns `true` if the difference is statistically significant at the specified alpha level.

```ruby
# Response time improvement: are new times significantly lower?
baseline_times = [150, 165, 155, 170, 160, 145, 175, 152, 158, 163] # ~159ms avg
optimized_times = [120, 125, 115, 130, 118, 122, 128, 124, 119, 126] # ~123ms avg

# Are optimized times significantly less (better) than baseline?
puts optimized_times.less_than?(baseline_times)  # => true (significant improvement)
puts baseline_times.less_than?(optimized_times)  # => false

# Error rate reduction: is new implementation significantly better?
old_error_rates = [0.025, 0.028, 0.024, 0.030, 0.026, 0.027, 0.029] # ~2.7% avg
new_error_rates = [0.012, 0.015, 0.013, 0.016, 0.014, 0.011, 0.013] # ~1.3% avg

puts new_error_rates.less_than?(old_error_rates)  # => true (significantly fewer errors)

# Memory usage optimization
before_optimization = [245, 250, 242, 255, 248, 253, 247] # ~248MB avg
after_optimization = [198, 205, 195, 210, 200, 202, 197]  # ~201MB avg

puts after_optimization.less_than?(before_optimization)  # => true (significant reduction)

# Custom alpha levels
puts optimized_times.less_than?(baseline_times, alpha: 0.01)  # More stringent test
puts optimized_times.less_than?(baseline_times, alpha: 0.10)  # More lenient test
```

#### Comparison Operators

The gem provides convenient operator shortcuts for statistical comparisons:

##### `#>(other, alpha: 0.05)` and `#<(other, alpha: 0.05)`

Shorthand operators for `greater_than?` and `less_than?` respectively.

```ruby
# Performance comparison using operators
baseline_times = [150, 165, 155, 170, 160, 145, 175]
optimized_times = [120, 125, 115, 130, 118, 122, 128]

# These are equivalent:
puts baseline_times.greater_than?(optimized_times)  # => true
puts baseline_times > optimized_times               # => true

puts optimized_times.less_than?(baseline_times)    # => true
puts optimized_times < baseline_times               # => true

# With custom alpha levels (use explicit method syntax for parameters)
puts baseline_times.>(optimized_times, alpha: 0.01)  # More stringent
puts optimized_times.<(baseline_times, alpha: 0.10)  # More lenient
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

# Use percentiles for SLA monitoring (industry standard approach)
p50 = clean_times.percentile(50)  # Median response time
p95 = clean_times.percentile(95)  # 95% of requests complete within this time
p99 = clean_times.percentile(99)  # 99% of requests complete within this time

puts "Response Time SLAs:"
puts "  p50 (median): #{p50.round(1)}ms"
puts "  p95: #{p95.round(1)}ms"
puts "  p99: #{p99.round(1)}ms"

# Set alerting thresholds based on percentiles
sla_p95_threshold = 200  # ms
if p95 > sla_p95_threshold
  puts "🚨 SLA BREACH: 95th percentile (#{p95.round(1)}ms) exceeds #{sla_p95_threshold}ms"
else
  puts "✅ SLA OK: 95th percentile within acceptable limits"
end

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

### Statistical Hypothesis Testing

```ruby
# Complete example: A/B testing with proper statistical analysis
# Testing whether a new checkout flow improves conversion rates

# Conversion rate data (percentages converted to decimals)
control_conversions = [0.118, 0.124, 0.116, 0.121, 0.119, 0.122, 0.117, 0.120, 0.115, 0.123]
variant_conversions = [0.135, 0.142, 0.138, 0.144, 0.140, 0.136, 0.139, 0.141, 0.137, 0.143]

puts "=== A/B Test Statistical Analysis ==="
puts "Control group (n=#{control_conversions.count}):"
puts "  Mean: #{(control_conversions.mean * 100).round(2)}%"
puts "  Std Dev: #{(control_conversions.standard_deviation * 100).round(3)}%"

puts "Variant group (n=#{variant_conversions.count}):"
puts "  Mean: #{(variant_conversions.mean * 100).round(2)}%"
puts "  Std Dev: #{(variant_conversions.standard_deviation * 100).round(3)}%"

# Calculate effect size
lift = variant_conversions.signed_percentage_difference(control_conversions)
puts "\nEffect size: #{lift.round(2)}% lift"

# Perform statistical test
t_statistic = control_conversions.t_value(variant_conversions)
degrees_freedom = control_conversions.degrees_of_freedom(variant_conversions)

puts "\nStatistical test results:"
puts "  t-statistic: #{t_statistic.round(3)}"
puts "  Degrees of freedom: #{degrees_freedom.round(1)}"
puts "  |t| = #{t_statistic.abs.round(3)}"

# Interpret results (simplified - in real analysis, use proper p-value lookup)
if t_statistic.abs > 2.0  # Rough threshold for significance
  significance = t_statistic.abs > 3.0 ? "highly significant" : "significant"
  direction = t_statistic < 0 ? "Variant is better" : "Control is better"
  puts "  Result: #{significance} difference detected"
  puts "  Conclusion: #{direction}"
else
  puts "  Result: No significant difference detected"
  puts "  Conclusion: Insufficient evidence for a difference"
end

# Data quality checks
control_outliers = control_conversions.outlier_stats
variant_outliers = variant_conversions.outlier_stats

puts "\nData quality:"
puts "  Control outliers: #{control_outliers[:outliers_removed]}/#{control_outliers[:original_count]}"
puts "  Variant outliers: #{variant_outliers[:outliers_removed]}/#{variant_outliers[:original_count]}"

if control_outliers[:outliers_removed] > 0 || variant_outliers[:outliers_removed] > 0
  puts "  ⚠️  Consider investigating outliers before concluding"
end
```

### Production Monitoring with Statistical Analysis

```ruby
# Monitor API performance changes after deployment
# Compare response times before and after optimization

before_deploy = [145, 152, 148, 159, 143, 156, 147, 151, 149, 154,
                 146, 158, 150, 153, 144, 157, 148, 152, 147, 155]

after_deploy = [132, 128, 135, 130, 133, 129, 131, 134, 127, 136,
                133, 130, 128, 135, 132, 129, 134, 131, 130, 133]

puts "=== Performance Monitoring Analysis ==="

# Remove outliers for more accurate comparison
before_clean = before_deploy.remove_outliers
after_clean = after_deploy.remove_outliers

puts "Before deployment (cleaned): #{before_clean.mean.round(1)}ms ± #{before_clean.standard_deviation.round(1)}ms"
puts "After deployment (cleaned): #{after_clean.mean.round(1)}ms ± #{after_clean.standard_deviation.round(1)}ms"

# Calculate improvement
improvement_pct = after_clean.signed_percentage_difference(before_clean)
improvement_abs = before_clean.mean - after_clean.mean

puts "Improvement: #{improvement_pct.round(1)}% (#{improvement_abs.round(1)}ms faster)"

# Statistical significance test
t_stat = before_clean.t_value(after_clean)
df = before_clean.degrees_of_freedom(after_clean)

puts "Statistical test: t(#{df.round(1)}) = #{t_stat.round(3)}"

if t_stat.abs > 2.5  # Conservative threshold for production changes
  puts "✅ Statistically significant improvement confirmed"
  puts "   Safe to keep the optimization"
else
  puts "⚠️  Improvement not statistically significant"
  puts "   Consider longer observation period"
end

# Monitor for performance regression alerts
alert_threshold = 2.0  # t-statistic threshold for alerts
if t_stat < -alert_threshold  # Negative means after > before (regression)
  puts "🚨 PERFORMANCE REGRESSION DETECTED!"
  puts "   Immediate investigation recommended"
end
```

## Method Reference

| Method | Description | Returns | Notes |
|--------|-------------|---------|-------|
| `mean` | Arithmetic mean | Float | Works with any numeric collection |
| `median` | Middle value | Numeric or nil | Returns nil for empty collections |
| `percentile(percentile)` | Value at specified percentile (0-100) | Numeric or nil | Uses linear interpolation, R-7/Excel method |
| `variance` | Sample variance | Float | Uses n-1 denominator (sample variance) |
| `standard_deviation` | Sample standard deviation | Float | Square root of variance |
| `t_value(other)` | T-statistic for hypothesis testing | Float | Uses Welch's t-test, handles unequal variances |
| `degrees_of_freedom(other)` | Degrees of freedom for t-test | Float | Uses Welch's formula, accounts for unequal variances |
| `greater_than?(other, alpha: 0.05)` | Test if mean is significantly greater | Boolean | One-tailed t-test, customizable alpha level |
| `less_than?(other, alpha: 0.05)` | Test if mean is significantly less | Boolean | One-tailed t-test, customizable alpha level |
| `>(other, alpha: 0.05)` | Alias for `greater_than?` | Boolean | Shorthand operator for statistical comparison |
| `<(other, alpha: 0.05)` | Alias for `less_than?` | Boolean | Shorthand operator for statistical comparison |
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

## Releasing

Tags a new version and pushes it to GitHub.

```bash
bundle exec rake release
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
