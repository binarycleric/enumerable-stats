# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Enumerable with EnumerableStats' do
  describe '#mean' do
    it 'calculates the mean of positive integers' do
      expect([1, 2, 3, 4, 5].mean).to eq(3.0)
    end

    it 'calculates the mean of mixed numbers' do
      expect([1, 2, 3, 4].mean).to eq(2.5)
    end

    it 'calculates the mean of negative numbers' do
      expect([-1, -2, -3].mean).to eq(-2.0)
    end

    it 'calculates the mean of floats' do
      expect([1.5, 2.5, 3.5].mean).to be_within(0.001).of(2.5)
    end

    it 'handles single element' do
      expect([42].mean).to eq(42.0)
    end

    it 'handles large numbers' do
      expect([1000, 2000, 3000].mean).to eq(2000.0)
    end
  end

  describe '#median' do
    it 'returns nil for empty array' do
      expect([].median).to be_nil
    end

    it 'calculates median for single element' do
      expect([5].median).to eq(5)
    end

    it 'calculates median for odd number of elements' do
      expect([1, 2, 3, 4, 5].median).to eq(3)
    end

    it 'calculates median for even number of elements' do
      expect([1, 2, 3, 4].median).to eq(2.5)
    end

    it 'calculates median for unsorted array' do
      expect([5, 1, 3, 2, 4].median).to eq(3)
    end

    it 'calculates median with negative numbers' do
      expect([-3, -1, 0, 1, 3].median).to eq(0)
    end

    it 'calculates median with floats' do
      expect([1.1, 2.2, 3.3].median).to eq(2.2)
    end

    it 'calculates median with duplicate values' do
      expect([1, 2, 2, 3].median).to eq(2.0)
    end
  end

  describe '#percentile' do
    it 'calculates basic percentiles correctly' do
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      expect(data.percentile(0)).to eq(1)     # Minimum
      expect(data.percentile(100)).to eq(10)  # Maximum
      expect(data.percentile(50)).to eq(5.5)  # Median
    end

    it 'calculates percentiles with documented examples' do
      data = [1, 2, 3, 4, 5]

      expect(data.percentile(50)).to eq(3)    # Same as median
      expect(data.percentile(25)).to eq(2.0)  # 25th percentile
      expect(data.percentile(75)).to eq(4.0)  # 75th percentile
      expect(data.percentile(0)).to eq(1)     # Minimum
      expect(data.percentile(100)).to eq(5)   # Maximum
    end

    it 'handles linear interpolation correctly' do
      data = [10, 20, 30, 40, 50]

      # 25th percentile should be between 20 and 30
      result = data.percentile(25)
      expect(result).to eq(20.0)

      # 37.5th percentile should interpolate
      result = data.percentile(37.5)
      expect(result).to eq(25.0)  # Halfway between 20 and 30

      # 62.5th percentile should interpolate
      result = data.percentile(62.5)
      expect(result).to eq(35.0)  # Halfway between 30 and 40
    end

    it 'works with unsorted data' do
      unsorted = [5, 1, 4, 2, 3]
      sorted = [1, 2, 3, 4, 5]

      expect(unsorted.percentile(50)).to eq(sorted.percentile(50))
      expect(unsorted.percentile(25)).to eq(sorted.percentile(25))
      expect(unsorted.percentile(75)).to eq(sorted.percentile(75))
    end

    it 'handles edge cases with small datasets' do
      # Single element
      expect([42].percentile(50)).to eq(42)
      expect([42].percentile(0)).to eq(42)
      expect([42].percentile(100)).to eq(42)

      # Two elements
      expect([10, 20].percentile(50)).to eq(15.0)  # Average of the two
      expect([10, 20].percentile(25)).to eq(12.5)
      expect([10, 20].percentile(75)).to eq(17.5)
    end

    it 'returns nil for empty collections' do
      expect([].percentile(50)).to be_nil
      expect([].percentile(0)).to be_nil
      expect([].percentile(100)).to be_nil
    end

    it 'validates percentile parameter' do
      data = [1, 2, 3, 4, 5]

      # Valid percentiles should work
      expect { data.percentile(0) }.not_to raise_error
      expect { data.percentile(50) }.not_to raise_error
      expect { data.percentile(100) }.not_to raise_error
      expect { data.percentile(25.5) }.not_to raise_error

      # Invalid percentiles should raise ArgumentError
      expect { data.percentile(-1) }.to raise_error(ArgumentError, /must be a number between 0 and 100/)
      expect { data.percentile(101) }.to raise_error(ArgumentError, /must be a number between 0 and 100/)
      expect { data.percentile("50") }.to raise_error(ArgumentError, /must be a number between 0 and 100/)
      expect { data.percentile(nil) }.to raise_error(ArgumentError, /must be a number between 0 and 100/)
    end

    it 'handles floating point percentiles' do
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      # Test decimal percentiles
      result = data.percentile(33.333)
      expect(result).to be_a(Numeric)
      expect(result).to be_within(0.01).of(3.99997)  # More precise expectation

      result = data.percentile(66.667)
      expect(result).to be_a(Numeric)
      expect(result).to be_within(0.01).of(7.00003)  # Handle floating point precision
    end

    it 'works with duplicate values' do
      data = [1, 2, 2, 2, 3, 4, 5]

      # Should handle duplicates correctly
      expect(data.percentile(50)).to eq(2)  # Median falls on duplicate value
      expect(data.percentile(25)).to eq(2.0)
      expect(data.percentile(75)).to be >= 3
    end

    it 'matches median calculation at 50th percentile' do
      # Test various datasets to ensure percentile(50) equals median
      test_datasets = [
        [1, 2, 3, 4, 5],
        [1, 2, 3, 4, 5, 6],
        [10, 20, 30, 40, 50, 60, 70],
        [1.5, 2.5, 3.5, 4.5],
        [-5, -1, 0, 1, 5]
      ]

      test_datasets.each do |dataset|
        expect(dataset.percentile(50)).to eq(dataset.median)
      end
    end

    it 'calculates quartiles correctly' do
      # Standard statistical example
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

      q1 = data.percentile(25)   # First quartile
      q2 = data.percentile(50)   # Second quartile (median)
      q3 = data.percentile(75)   # Third quartile

      expect(q1).to be < q2
      expect(q2).to be < q3
      expect(q1).to be_between(3, 4)
      expect(q2).to eq(6.5)  # Median of 12 elements
      expect(q3).to be_between(9, 10)
    end

    it 'handles performance data scenarios' do
      # API response times example
      response_times = [45, 52, 48, 51, 49, 47, 53, 46, 50, 54, 55, 44, 56, 43, 57]

      p95 = response_times.percentile(95)
      p99 = response_times.percentile(99)
      p50 = response_times.percentile(50)

      expect(p95).to be > p50
      expect(p99).to be >= p95
      expect(p50).to eq(response_times.median)
    end

    it 'works with negative numbers' do
      data = [-10, -5, 0, 5, 10]

      expect(data.percentile(0)).to eq(-10)
      expect(data.percentile(50)).to eq(0)
      expect(data.percentile(100)).to eq(10)
      expect(data.percentile(25)).to eq(-5.0)
      expect(data.percentile(75)).to eq(5.0)
    end

    it 'maintains precision with floating point numbers' do
      data = [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0]

      result = data.percentile(25)
      expect(result).to be_within(0.001).of(1.325)

      result = data.percentile(75)
      expect(result).to be_within(0.001).of(1.775)
    end
  end

  describe '#variance' do
    it 'calculates variance for simple dataset' do
      # Sample variance of [1, 2, 3, 4, 5]
      # Mean = 3, variance = ((1-3)² + (2-3)² + (3-3)² + (4-3)² + (5-3)²) / (5-1)
      # = (4 + 1 + 0 + 1 + 4) / 4 = 10/4 = 2.5
      expect([1, 2, 3, 4, 5].variance).to eq(2.5)
    end

    it 'calculates variance for identical values' do
      expect([5, 5, 5, 5].variance).to eq(0.0)
    end

    it 'calculates variance for two values' do
      # Mean = 1.5, variance = ((1-1.5)² + (2-1.5)²) / 1 = (0.25 + 0.25) / 1 = 0.5
      expect([1, 2].variance).to eq(0.5)
    end

    it 'calculates variance with negative numbers' do
      expect([-1, 0, 1].variance).to eq(1.0)
    end

    it 'calculates variance with floats' do
      result = [1.5, 2.5, 3.5].variance
      expect(result).to be_within(0.001).of(1.0)
    end
  end

  describe '#standard_deviation' do
    it 'calculates standard deviation' do
      # Variance of [1,2,3,4,5] is 2.5, so std dev is sqrt(2.5) ≈ 1.58
      expect([1, 2, 3, 4, 5].standard_deviation).to be_within(0.01).of(1.58)
    end

    it 'calculates standard deviation for identical values' do
      expect([5, 5, 5, 5].standard_deviation).to eq(0.0)
    end

    it 'calculates standard deviation for simple case' do
      # Variance of [1, 2] is 0.5, so std dev is sqrt(0.5) ≈ 0.707
      expect([1, 2].standard_deviation).to be_within(0.001).of(0.707)
    end
  end

  describe '#remove_outliers' do
    context 'with insufficient data points' do
      it 'returns original array when less than 4 elements' do
        expect([1].remove_outliers).to eq([1])
        expect([1, 2].remove_outliers).to eq([1, 2])
        expect([1, 2, 3].remove_outliers).to eq([1, 2, 3])
      end
    end

    context 'with normal dataset' do
      let(:data) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 100] } # 100 is an outlier

      it 'removes outliers using default multiplier' do
        result = data.remove_outliers
        expect(result).not_to include(100)
        expect(result.length).to be < data.length
      end

      it 'removes outliers using custom multiplier' do
        # More conservative multiplier should keep more data
        conservative_result = data.remove_outliers(multiplier: 3.0)
        standard_result = data.remove_outliers(multiplier: 1.5)

        expect(conservative_result.length).to be >= standard_result.length
      end

      it 'handles dataset with no outliers' do
        normal_data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        result = normal_data.remove_outliers
        expect(result.size).to eq(normal_data.size)
      end
    end

    context 'with extreme outliers' do
      it 'removes multiple outliers' do
        data = [1, 2, 3, 4, 5, 6, 7, 8, 1000, 2000]
        result = data.remove_outliers
        expect(result).not_to include(1000, 2000)
        expect(result.size).to be < data.size
      end

      it 'removes lower outliers' do
        data = [-100, 1, 2, 3, 4, 5, 6, 7]
        result = data.remove_outliers
        expect(result).not_to include(-100)
      end
    end

    context 'with performance data scenario' do
      it 'handles typical performance metrics with outliers' do
        # Simulating response times in milliseconds
        response_times = [10, 12, 11, 13, 14, 12, 15, 11, 13, 500, 600] # Last two are outliers
        result = response_times.remove_outliers

        expect(result.max).to be < 100 # Outliers should be removed
        expect(result.length).to be < response_times.length
      end
    end

    context 'with floating point numbers' do
      it 'works with decimal values' do
        data = [1.1, 1.2, 1.3, 1.4, 1.5, 10.0] # 10.0 is an outlier
        result = data.remove_outliers
        expect(result).not_to include(10.0)
      end
    end
  end

  describe '#outlier_stats' do
    let(:data_with_outliers) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 100] }
    let(:data_without_outliers) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }

    it 'returns correct statistics when outliers are present' do
      stats = data_with_outliers.outlier_stats

      expect(stats[:original_count]).to eq(10)
      expect(stats[:filtered_count]).to be < 10
      expect(stats[:outliers_removed]).to be > 0
      expect(stats[:outlier_percentage]).to be > 0
    end

    it 'returns correct statistics when no outliers are present' do
      stats = data_without_outliers.outlier_stats

      expect(stats[:original_count]).to eq(10)
      expect(stats[:filtered_count]).to eq(10)
      expect(stats[:outliers_removed]).to eq(0)
      expect(stats[:outlier_percentage]).to eq(0.0)
    end

    it 'calculates percentage correctly' do
      # If 1 out of 10 values is removed, percentage should be 10%
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 100]
      stats = data.outlier_stats

      expect(stats[:outlier_percentage]).to be_within(0.1).of(10.0)
    end

    it 'respects custom multiplier' do
      conservative_stats = data_with_outliers.outlier_stats(multiplier: 3.0)
      standard_stats = data_with_outliers.outlier_stats(multiplier: 1.5)

      expect(conservative_stats[:outliers_removed]).to be <= standard_stats[:outliers_removed]
    end

    it 'returns hash with all required keys' do
      stats = data_with_outliers.outlier_stats

      expect(stats).to have_key(:original_count)
      expect(stats).to have_key(:filtered_count)
      expect(stats).to have_key(:outliers_removed)
      expect(stats).to have_key(:outlier_percentage)
    end

    it 'handles small datasets correctly' do
      small_data = [1, 2, 3]
      stats = small_data.outlier_stats

      expect(stats[:original_count]).to eq(3)
      expect(stats[:filtered_count]).to eq(3) # No outliers removed for < 4 elements
      expect(stats[:outliers_removed]).to eq(0)
      expect(stats[:outlier_percentage]).to eq(0.0)
    end
  end

  describe 'integration with different enumerable types' do
    it 'works with ranges' do
      expect((1..5).mean).to eq(3.0)
      expect((1..5).median).to eq(3)
    end

    it 'works with sets' do
      require 'set'
      data = Set.new([1, 2, 3, 4, 5])
      expect(data.mean).to eq(3.0)
      expect(data.variance).to eq(2.5)
    end
  end

  describe '#percentage_difference' do
    it 'calculates percentage difference between two collections' do
      a = [10, 20, 30]  # mean = 20
      b = [15, 25, 35]  # mean = 25

      # Percentage difference = |20 - 25| / ((20 + 25) / 2) * 100 = 5 / 22.5 * 100 ≈ 22.22%
      result = a.percentage_difference(b)
      expect(result).to be_within(0.01).of(22.22)
    end

    it 'calculates percentage difference between collection and single value' do
      data = [10, 20, 30]  # mean = 20

      # Percentage difference = |20 - 25| / ((20 + 25) / 2) * 100 = 22.22%
      result = data.percentage_difference(25)
      expect(result).to be_within(0.01).of(22.22)
    end

    it 'returns 0 when comparing identical means' do
      a = [10, 20, 30]
      b = [5, 20, 35]  # Both have mean = 20

      expect(a.percentage_difference(b)).to eq(0.0)
    end

    it 'returns 0 when comparing with same value as mean' do
      data = [10, 20, 30]  # mean = 20
      expect(data.percentage_difference(20)).to eq(0.0)
    end

    it 'handles large percentage differences' do
      small = [1, 2, 3]     # mean = 2
      large = [100, 200, 300] # mean = 200

      # Percentage difference = |2 - 200| / ((2 + 200) / 2) * 100 = 198 / 101 * 100 ≈ 196.04%
      result = small.percentage_difference(large)
      expect(result).to be_within(0.01).of(196.04)
    end

    it 'always returns positive values' do
      a = [10, 20, 30]  # mean = 20
      b = [5, 15, 25]   # mean = 15

      expect(a.percentage_difference(b)).to be > 0
      expect(b.percentage_difference(a)).to be > 0
      expect(a.percentage_difference(b)).to eq(b.percentage_difference(a))
    end

    it 'handles edge case when sum is zero' do
      data = [-10, 0, 10]  # mean = 0
      result = data.percentage_difference(0)
      expect(result).to eq(0.0)

      # When both values sum to 0 but are different, should return infinity
      result = data.percentage_difference(-0.0)
      expect(result).to eq(0.0)
    end

    it 'returns infinity when denominator approaches zero with different values' do
      data = [1, 1, 1]  # mean = 1
      result = data.percentage_difference(-1)
      expect(result).to eq(Float::INFINITY)
    end

    it 'works with floating point collections' do
      a = [1.5, 2.5, 3.5]  # mean = 2.5
      b = [2.0, 3.0, 4.0]  # mean = 3.0

      # Percentage difference = |2.5 - 3.0| / ((2.5 + 3.0) / 2) * 100 = 0.5 / 2.75 * 100 ≈ 18.18%
      result = a.percentage_difference(b)
      expect(result).to be_within(0.01).of(18.18)
    end
  end

  describe '#t_value' do
    it 'calculates t-statistic for two samples with different means' do
      control = [10, 12, 11, 13, 12]     # mean = 11.6, std = 1.14
      treatment = [15, 17, 16, 18, 14]   # mean = 16.0, std = 1.58

      t_stat = control.t_value(treatment)
      expect(t_stat).to be < 0  # Control mean < treatment mean, so negative t-stat
      expect(t_stat.abs).to be > 3  # Should be significant difference

      # Reverse should give opposite sign
      reverse_t_stat = treatment.t_value(control)
      expect(reverse_t_stat).to be > 0
      expect(reverse_t_stat).to be_within(0.01).of(-t_stat)
    end

    it 'calculates t-statistic for samples with similar means' do
      sample_a = [10, 11, 12, 13, 14]
      sample_b = [11, 12, 13, 14, 15]  # Mean shifted by 1

      t_stat = sample_a.t_value(sample_b)
      expect(t_stat.abs).to be < 3  # Should be smaller difference
    end

    it 'returns zero when comparing identical samples' do
      sample = [10, 12, 14, 16, 18]
      identical = [10, 12, 14, 16, 18]

      t_stat = sample.t_value(identical)
      expect(t_stat).to eq(0.0)
    end

    it 'handles samples with different variances correctly' do
      low_variance = [10, 10.1, 10.2, 10.1, 10]      # Very consistent
      high_variance = [5, 15, 8, 12, 20]             # Very variable, similar mean

      t_stat = low_variance.t_value(high_variance)
      expect(t_stat).to respond_to(:abs)  # Should be a valid number
      expect(t_stat).not_to be_nan
      expect(t_stat).not_to be_infinite
    end

    it 'handles edge case with zero standard deviation' do
      constant = [5, 5, 5, 5, 5]     # Zero standard deviation
      variable = [4, 5, 6, 5, 5]     # Some variation

      # This should still work (denominator won't be zero due to variable sample)
      t_stat = constant.t_value(variable)
      expect(t_stat).to respond_to(:abs)
      expect(t_stat).not_to be_nan
    end

    it 'produces expected values for known statistical examples' do
      # Classical example: comparing two groups
      group_a = [2.1, 1.9, 2.0, 2.2, 1.8, 2.0, 2.1]  # mean ≈ 2.01
      group_b = [2.8, 2.9, 2.7, 3.0, 2.6, 2.8, 2.9]  # mean ≈ 2.81

      t_stat = group_a.t_value(group_b)
      expect(t_stat).to be < -5  # Should be strongly negative (group_a < group_b)
      expect(t_stat.abs).to be > 5  # Should indicate significant difference
    end

    it 'works with floating point precision' do
      precise_a = [1.001, 1.002, 1.003, 1.004, 1.005]
      precise_b = [1.006, 1.007, 1.008, 1.009, 1.010]

      t_stat = precise_a.t_value(precise_b)
      expect(t_stat).to be < 0
      expect(t_stat.abs).to be > 1  # Even small differences should be detectable
    end
  end

  describe '#degrees_of_freedom' do
    it 'calculates degrees of freedom using Welch formula' do
      sample_a = [10, 12, 14, 16, 18]    # n=5, variance ≈ 10
      sample_b = [5, 15, 25, 35, 45, 55] # n=6, much higher variance

      df = sample_a.degrees_of_freedom(sample_b)
      expect(df).to be > 0
      expect(df).to be < (sample_a.count + sample_b.count - 2)  # Should be less than pooled DF
    end

    it 'approaches pooled degrees of freedom when variances are equal' do
      # Create samples with similar variances
      sample_a = [10, 11, 12, 13, 14]  # n=5, variance = 2.5
      sample_b = [15, 16, 17, 18, 19]  # n=5, variance = 2.5

      df = sample_a.degrees_of_freedom(sample_b)
      pooled_df = sample_a.count + sample_b.count - 2  # = 8

      # Should be close to pooled DF when variances are equal
      expect(df).to be_within(1.0).of(pooled_df)
    end

    it 'handles samples with very different variances' do
      uniform = [10, 10, 10, 10, 10]      # Almost no variance
      variable = [1, 5, 10, 15, 25, 30]   # High variance

      df = uniform.degrees_of_freedom(variable)
      expect(df).to be > 0
      expect(df).to be < 10  # Should be much less than pooled DF due to unequal variances
    end

    it 'returns symmetric result regardless of order' do
      sample_a = [1, 3, 5, 7, 9]
      sample_b = [2, 4, 6, 8, 10, 12, 14]

      df_a_b = sample_a.degrees_of_freedom(sample_b)
      df_b_a = sample_b.degrees_of_freedom(sample_a)

      expect(df_a_b).to be_within(0.001).of(df_b_a)
    end

    it 'handles edge case with minimum sample sizes' do
      small_a = [1, 2]    # n=2 (minimum for variance calculation)
      small_b = [3, 4, 5] # n=3

      df = small_a.degrees_of_freedom(small_b)
      expect(df).to be > 0
      expect(df).to be < 3  # Less than pooled DF
    end

    it 'produces expected values for textbook examples' do
      # Example from statistics textbook: comparing two teaching methods
      method_a = [85, 87, 83, 89, 86, 84, 88]  # n=7, more consistent
      method_b = [82, 91, 88, 85, 94, 87]      # n=6, more variable

      df = method_a.degrees_of_freedom(method_b)
      expect(df).to be_between(6, 11)  # Expected range for this type of comparison
      expect(df).to be < (method_a.count + method_b.count - 2)  # Should be less than pooled DF (11)
    end

    it 'handles identical samples' do
      sample = [1, 2, 3, 4, 5]
      identical = [1, 2, 3, 4, 5]

      df = sample.degrees_of_freedom(identical)
      expect(df).to be_within(0.1).of(8.0)  # Should approach n1 + n2 - 2
    end
  end

  describe '#signed_percentage_difference' do
    it 'calculates signed percentage difference between two collections' do
      a = [10, 20, 30]  # mean = 20
      b = [15, 25, 35]  # mean = 25

      # Signed percentage difference = (20 - 25) / ((20 + 25) / 2) * 100 = -5 / 22.5 * 100 ≈ -22.22%
      result = a.signed_percentage_difference(b)
      expect(result).to be_within(0.01).of(-22.22)

      # Reverse should be positive
      result = b.signed_percentage_difference(a)
      expect(result).to be_within(0.01).of(22.22)
    end

    it 'calculates signed percentage difference between collection and single value' do
      data = [10, 20, 30]  # mean = 20

      # When collection mean < comparison value, result should be negative
      result = data.signed_percentage_difference(25)
      expect(result).to be_within(0.01).of(-22.22)

      # When collection mean > comparison value, result should be positive
      result = data.signed_percentage_difference(15)
      expect(result).to be_within(0.01).of(28.57)
    end

    it 'returns 0 when comparing identical means' do
      a = [10, 20, 30]
      b = [5, 20, 35]  # Both have mean = 20

      expect(a.signed_percentage_difference(b)).to eq(0.0)
    end

    it 'shows direction of difference correctly' do
      baseline = [100, 100, 100]  # mean = 100
      improved = [90, 90, 90]     # mean = 90 (10% better for latency)
      regressed = [110, 110, 110] # mean = 110 (10% worse for latency)

      # Improved (lower) should show negative percentage
      result = improved.signed_percentage_difference(baseline)
      expect(result).to be < 0

      # Regressed (higher) should show positive percentage
      result = regressed.signed_percentage_difference(baseline)
      expect(result).to be > 0
    end

    it 'handles performance monitoring scenarios' do
      # API response times in milliseconds
      baseline_times = [100, 120, 110, 105, 115]  # mean = 110
      optimized_times = [95, 105, 100, 98, 102]   # mean = 100

      # Optimized times are 9.52% better (negative is good for response times)
      improvement = optimized_times.signed_percentage_difference(baseline_times)
      expect(improvement).to be_within(0.1).of(-9.52)

      # From baseline perspective, it's a 9.52% increase (positive)
      change = baseline_times.signed_percentage_difference(optimized_times)
      expect(change).to be_within(0.1).of(9.52)
    end

    it 'handles A/B testing scenarios' do
      # Conversion rates
      control_rates = [0.12, 0.11, 0.13, 0.12, 0.12]    # mean = 0.12 (12%)
      variant_rates = [0.14, 0.13, 0.15, 0.14, 0.14]    # mean = 0.14 (14%)

      # Variant is 15.38% better than control
      improvement = variant_rates.signed_percentage_difference(control_rates)
      expect(improvement).to be_within(0.1).of(15.38)
    end

    it 'returns infinity when denominator approaches zero with different values' do
      data = [1, 1, 1]  # mean = 1
      result = data.signed_percentage_difference(-1)
      expect(result).to eq(Float::INFINITY)
    end

    it 'preserves sign correctly for large differences' do
      small = [1, 2, 3]     # mean = 2
      large = [100, 200, 300] # mean = 200

      # Small compared to large should be negative
      result = small.signed_percentage_difference(large)
      expect(result).to be < 0
      expect(result).to be_within(0.01).of(-196.04)

      # Large compared to small should be positive
      result = large.signed_percentage_difference(small)
      expect(result).to be > 0
      expect(result).to be_within(0.01).of(196.04)
    end
  end

  describe 'edge cases and error conditions' do
    it 'handles very large datasets efficiently' do
      large_data = (1..1000).to_a + [10000] # One outlier in 1000 points

      expect { large_data.remove_outliers }.not_to raise_error
      expect(large_data.remove_outliers).not_to include(10000)
    end

    it 'handles datasets with all identical values' do
      identical_data = [5] * 10

      expect(identical_data.mean).to eq(5.0)
      expect(identical_data.median).to eq(5.0)
      expect(identical_data.variance).to eq(0.0)
      expect(identical_data.standard_deviation).to eq(0.0)
      expect(identical_data.remove_outliers).to eq(identical_data)
    end

    it 'handles mixed integer and float data' do
      mixed_data = [1, 2.5, 3, 4.7, 5]

      expect { mixed_data.mean }.not_to raise_error
      expect { mixed_data.median }.not_to raise_error
      expect { mixed_data.remove_outliers }.not_to raise_error
    end
  end
end