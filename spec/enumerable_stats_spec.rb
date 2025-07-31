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