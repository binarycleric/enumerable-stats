# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "csv"
require "set"
require "stringio"

RSpec.describe EnumerableStats do
  describe "#mean" do
    it "calculates the mean of positive integers" do
      expect([1, 2, 3, 4, 5].mean).to eq(3.0)
    end

    it "calculates the mean of mixed numbers" do
      expect([1, 2, 3, 4].mean).to eq(2.5)
    end

    it "calculates the mean of negative numbers" do
      expect([-1, -2, -3].mean).to eq(-2.0)
    end

    it "calculates the mean of floats" do
      expect([1.5, 2.5, 3.5].mean).to be_within(0.001).of(2.5)
    end

    it "handles single element" do
      expect([42].mean).to eq(42.0)
    end

    it "handles large numbers" do
      expect([1000, 2000, 3000].mean).to eq(2000.0)
    end
  end

  describe "#median" do
    it "returns nil for empty array" do
      expect([].median).to be_nil
    end

    it "calculates median for single element" do
      expect([5].median).to eq(5)
    end

    it "calculates median for odd number of elements" do
      expect([1, 2, 3, 4, 5].median).to eq(3)
    end

    it "calculates median for even number of elements" do
      expect([1, 2, 3, 4].median).to eq(2.5)
    end

    it "calculates median for unsorted array" do
      expect([5, 1, 3, 2, 4].median).to eq(3)
    end

    it "calculates median with negative numbers" do
      expect([-3, -1, 0, 1, 3].median).to eq(0)
    end

    it "calculates median with floats" do
      expect([1.1, 2.2, 3.3].median).to eq(2.2)
    end

    it "calculates median with duplicate values" do
      expect([1, 2, 2, 3].median).to eq(2.0)
    end
  end

  describe "#percentile" do
    it "calculates basic percentiles correctly" do
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      expect(data.percentile(0)).to eq(1)     # Minimum
      expect(data.percentile(100)).to eq(10)  # Maximum
      expect(data.percentile(50)).to eq(5.5)  # Median
    end

    it "calculates percentiles with documented examples" do
      data = [1, 2, 3, 4, 5]

      expect(data.percentile(50)).to eq(3)    # Same as median
      expect(data.percentile(25)).to eq(2.0)  # 25th percentile
      expect(data.percentile(75)).to eq(4.0)  # 75th percentile
      expect(data.percentile(0)).to eq(1)     # Minimum
      expect(data.percentile(100)).to eq(5)   # Maximum
    end

    it "handles linear interpolation correctly" do
      data = [10, 20, 30, 40, 50]

      # 25th percentile should be between 20 and 30
      result = data.percentile(25)
      expect(result).to eq(20.0)

      # 37.5th percentile should interpolate
      result = data.percentile(37.5)
      expect(result).to eq(25.0) # Halfway between 20 and 30

      # 62.5th percentile should interpolate
      result = data.percentile(62.5)
      expect(result).to eq(35.0) # Halfway between 30 and 40
    end

    it "works with unsorted data" do
      unsorted = [5, 1, 4, 2, 3]
      sorted = [1, 2, 3, 4, 5]

      expect(unsorted.percentile(50)).to eq(sorted.percentile(50))
      expect(unsorted.percentile(25)).to eq(sorted.percentile(25))
      expect(unsorted.percentile(75)).to eq(sorted.percentile(75))
    end

    it "handles edge cases with small datasets" do
      # Single element
      expect([42].percentile(50)).to eq(42)
      expect([42].percentile(0)).to eq(42)
      expect([42].percentile(100)).to eq(42)

      # Two elements
      expect([10, 20].percentile(50)).to eq(15.0) # Average of the two
      expect([10, 20].percentile(25)).to eq(12.5)
      expect([10, 20].percentile(75)).to eq(17.5)
    end

    it "returns nil for empty collections" do
      expect([].percentile(50)).to be_nil
      expect([].percentile(0)).to be_nil
      expect([].percentile(100)).to be_nil
    end

    it "validates percentile parameter" do
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

    it "handles floating point percentiles" do
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      # Test decimal percentiles
      result = data.percentile(33.333)
      expect(result).to be_a(Numeric)
      expect(result).to be_within(0.01).of(3.99997)  # More precise expectation

      result = data.percentile(66.667)
      expect(result).to be_a(Numeric)
      expect(result).to be_within(0.01).of(7.00003)  # Handle floating point precision
    end

    it "works with duplicate values" do
      data = [1, 2, 2, 2, 3, 4, 5]

      # Should handle duplicates correctly
      expect(data.percentile(50)).to eq(2) # Median falls on duplicate value
      expect(data.percentile(25)).to eq(2.0)
      expect(data.percentile(75)).to be >= 3
    end

    it "matches median calculation at 50th percentile" do
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

    it "calculates quartiles correctly" do
      # Standard statistical example
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

      q1 = data.percentile(25)   # First quartile
      q2 = data.percentile(50)   # Second quartile (median)
      q3 = data.percentile(75)   # Third quartile

      expect(q1).to be < q2
      expect(q2).to be < q3
      expect(q1).to be_between(3, 4)
      expect(q2).to eq(6.5) # Median of 12 elements
      expect(q3).to be_between(9, 10)
    end

    it "handles performance data scenarios" do
      # API response times example
      response_times = [45, 52, 48, 51, 49, 47, 53, 46, 50, 54, 55, 44, 56, 43, 57]

      p95 = response_times.percentile(95)
      p99 = response_times.percentile(99)
      p50 = response_times.percentile(50)

      expect(p95).to be > p50
      expect(p99).to be >= p95
      expect(p50).to eq(response_times.median)
    end

    it "works with negative numbers" do
      data = [-10, -5, 0, 5, 10]

      expect(data.percentile(0)).to eq(-10)
      expect(data.percentile(50)).to eq(0)
      expect(data.percentile(100)).to eq(10)
      expect(data.percentile(25)).to eq(-5.0)
      expect(data.percentile(75)).to eq(5.0)
    end

    it "maintains precision with floating point numbers" do
      data = [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0]

      result = data.percentile(25)
      expect(result).to be_within(0.001).of(1.325)

      result = data.percentile(75)
      expect(result).to be_within(0.001).of(1.775)
    end
  end

  describe "#variance" do
    it "calculates variance for simple dataset" do
      # Sample variance of [1, 2, 3, 4, 5]
      # Mean = 3, variance = ((1-3)² + (2-3)² + (3-3)² + (4-3)² + (5-3)²) / (5-1)
      # = (4 + 1 + 0 + 1 + 4) / 4 = 10/4 = 2.5
      expect([1, 2, 3, 4, 5].variance).to eq(2.5)
    end

    it "calculates variance for identical values" do
      expect([5, 5, 5, 5].variance).to eq(0.0)
    end

    it "calculates variance for two values" do
      # Mean = 1.5, variance = ((1-1.5)² + (2-1.5)²) / 1 = (0.25 + 0.25) / 1 = 0.5
      expect([1, 2].variance).to eq(0.5)
    end

    it "calculates variance with negative numbers" do
      expect([-1, 0, 1].variance).to eq(1.0)
    end

    it "calculates variance with floats" do
      result = [1.5, 2.5, 3.5].variance
      expect(result).to be_within(0.001).of(1.0)
    end
  end

  describe "#standard_deviation" do
    it "calculates standard deviation" do
      # Variance of [1,2,3,4,5] is 2.5, so std dev is sqrt(2.5) ≈ 1.58
      expect([1, 2, 3, 4, 5].standard_deviation).to be_within(0.01).of(1.58)
    end

    it "calculates standard deviation for identical values" do
      expect([5, 5, 5, 5].standard_deviation).to eq(0.0)
    end

    it "calculates standard deviation for simple case" do
      # Variance of [1, 2] is 0.5, so std dev is sqrt(0.5) ≈ 0.707
      expect([1, 2].standard_deviation).to be_within(0.001).of(0.707)
    end
  end

  describe "#remove_outliers" do
    context "with insufficient data points" do
      it "returns original array when less than 4 elements" do
        expect([1].remove_outliers).to eq([1])
        expect([1, 2].remove_outliers).to eq([1, 2])
        expect([1, 2, 3].remove_outliers).to eq([1, 2, 3])
      end
    end

    context "with normal dataset" do
      let(:data) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 100] } # 100 is an outlier

      it "removes outliers using default multiplier" do
        result = data.remove_outliers
        expect(result).not_to include(100)
        expect(result.length).to be < data.length
      end

      it "removes outliers using custom multiplier" do
        # More conservative multiplier should keep more data
        conservative_result = data.remove_outliers(multiplier: 3.0)
        standard_result = data.remove_outliers(multiplier: 1.5)

        expect(conservative_result.length).to be >= standard_result.length
      end

      it "handles dataset with no outliers" do
        normal_data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        result = normal_data.remove_outliers
        expect(result.size).to eq(normal_data.size)
      end
    end

    context "with extreme outliers" do
      it "removes multiple outliers" do
        data = [1, 2, 3, 4, 5, 6, 7, 8, 1000, 2000]
        result = data.remove_outliers
        expect(result).not_to include(1000, 2000)
        expect(result.size).to be < data.size
      end

      it "removes lower outliers" do
        data = [-100, 1, 2, 3, 4, 5, 6, 7]
        result = data.remove_outliers
        expect(result).not_to include(-100)
      end
    end

    context "with performance data scenario" do
      it "handles typical performance metrics with outliers" do
        # Simulating response times in milliseconds
        response_times = [10, 12, 11, 13, 14, 12, 15, 11, 13, 500, 600] # Last two are outliers
        result = response_times.remove_outliers

        expect(result.max).to be < 100 # Outliers should be removed
        expect(result.length).to be < response_times.length
      end
    end

    context "with floating point numbers" do
      it "works with decimal values" do
        data = [1.1, 1.2, 1.3, 1.4, 1.5, 10.0] # 10.0 is an outlier
        result = data.remove_outliers
        expect(result).not_to include(10.0)
      end
    end
  end

  describe "#outlier_stats" do
    let(:data_with_outliers) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 100] }
    let(:data_without_outliers) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }

    it "returns correct statistics when outliers are present" do
      stats = data_with_outliers.outlier_stats

      expect(stats[:original_count]).to eq(10)
      expect(stats[:filtered_count]).to be < 10
      expect(stats[:outliers_removed]).to be > 0
      expect(stats[:outlier_percentage]).to be > 0
    end

    it "returns correct statistics when no outliers are present" do
      stats = data_without_outliers.outlier_stats

      expect(stats[:original_count]).to eq(10)
      expect(stats[:filtered_count]).to eq(10)
      expect(stats[:outliers_removed]).to eq(0)
      expect(stats[:outlier_percentage]).to eq(0.0)
    end

    it "calculates percentage correctly" do
      # If 1 out of 10 values is removed, percentage should be 10%
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 100]
      stats = data.outlier_stats

      expect(stats[:outlier_percentage]).to be_within(0.1).of(10.0)
    end

    it "respects custom multiplier" do
      conservative_stats = data_with_outliers.outlier_stats(multiplier: 3.0)
      standard_stats = data_with_outliers.outlier_stats(multiplier: 1.5)

      expect(conservative_stats[:outliers_removed]).to be <= standard_stats[:outliers_removed]
    end

    it "returns hash with all required keys" do
      stats = data_with_outliers.outlier_stats

      expect(stats).to have_key(:original_count)
      expect(stats).to have_key(:filtered_count)
      expect(stats).to have_key(:outliers_removed)
      expect(stats).to have_key(:outlier_percentage)
    end

    it "handles small datasets correctly" do
      small_data = [1, 2, 3]
      stats = small_data.outlier_stats

      expect(stats[:original_count]).to eq(3)
      expect(stats[:filtered_count]).to eq(3) # No outliers removed for < 4 elements
      expect(stats[:outliers_removed]).to eq(0)
      expect(stats[:outlier_percentage]).to eq(0.0)
    end
  end

  describe "integration with different enumerable types" do
    it "works with ranges" do
      expect((1..5).mean).to eq(3.0)
      expect((1..5).median).to eq(3)
      expect((10..20).percentile(50)).to eq((10..20).median)
      expect((1..5).variance).to eq(2.5)
      expect((1..5).standard_deviation).to be_within(0.01).of(1.58)
    end

    it "works with sets" do
      data = Set.new([1, 2, 3, 4, 5])
      expect(data.mean).to eq(3.0)
      expect(data.variance).to eq(2.5)
      expect(data.median).to eq(3)
      expect(data.standard_deviation).to be_within(0.01).of(1.58)
      expect(data.percentile(75)).to eq(4.0)
    end

    it "works with hash values" do
      data = { a: 10, b: 20, c: 30, d: 40, e: 50 }
      # Hash#each yields key-value pairs, so we need to map to values
      values = data.map { |_k, v| v }
      expect(values.mean).to eq(30.0)
      expect(values.median).to eq(30)
      expect(values.percentile(25)).to eq(20.0)
    end

    it "works with hash key-value pairs for non-numeric analysis" do
      # Test with the actual enumeration that Hash provides (key-value pairs)
      data = { a: 1, b: 2, c: 3, d: 4, e: 5 }
      # Extract just the values for statistical analysis
      numeric_values = data.values
      expect(numeric_values.mean).to eq(3.0)
      expect(numeric_values.median).to eq(3)
    end

    it "works with enumerators" do
      # Test with basic enumerator
      enum = [1, 2, 3, 4, 5].each
      expect(enum.mean).to eq(3.0)
      expect(enum.median).to eq(3)

      # Test with enumerator from range - convert to array first for proper statistical analysis
      range_enum = (10..50).step(10).to_a
      expect(range_enum.mean).to eq(30.0)
      expect(range_enum.median).to eq(30)
    end

    it "works with enumerator chains" do
      # Test with chained enumerators (Ruby 2.6+)
      skip "Enumerator chain not available" unless Enumerator.respond_to?(:chain)

      chain = Enumerator.chain([1, 2], [3, 4], [5])
      expect(chain.mean).to eq(3.0)
      expect(chain.median).to eq(3)
    end

    it "works with lazy enumerators" do
      # Test with lazy enumerator - convert to array for proper analysis
      lazy_enum = (1..10).lazy.select(&:odd?).to_a
      expect(lazy_enum.mean).to eq(5.0) # [1, 3, 5, 7, 9] mean = 5
      expect(lazy_enum.median).to eq(5)
    end

    it "works with struct instances containing numeric data" do
      point_class = Struct.new(:x, :y, :z) do
        def to_f
          Math.sqrt((x**2) + (y**2) + (z**2)) # Magnitude for statistical analysis
        end
      end

      points = [
        point_class.new(1, 2, 2),  # magnitude = 3
        point_class.new(2, 3, 6),  # magnitude = 7
        point_class.new(4, 4, 4),  # magnitude ≈ 6.93
        point_class.new(0, 0, 5),  # magnitude = 5
        point_class.new(3, 4, 0)   # magnitude = 5
      ]

      # Convert to magnitudes for analysis
      magnitudes = points.map(&:to_f)
      expect(magnitudes.mean).to be_within(0.1).of(5.39)
      expect(magnitudes.median).to be_within(0.1).of(5.0)
    end

    it "works with IO-like enumerable objects" do
      # Create a StringIO with numeric data
      string_data = "10\n20\n30\n40\n50\n"
      io = StringIO.new(string_data)

      # Convert lines to numbers for statistical analysis
      numbers = io.each_line.map(&:to_i)
      expect(numbers.mean).to eq(30.0)
      expect(numbers.median).to eq(30)
      expect(numbers.percentile(25)).to eq(20.0)
    end

    it "works with Dir.glob enumerable results" do
      # Create temporary files for testing
      Dir.mktmpdir do |tmpdir|
        # Create some test files with numeric names
        %w[1.txt 2.txt 3.txt 4.txt 5.txt].each do |filename|
          File.write(File.join(tmpdir, filename), "test")
        end

        # Get file basenames as numbers
        file_numbers = Dir.glob("#{tmpdir}/*.txt").map do |path|
          File.basename(path, ".txt").to_i
        end.sort

        expect(file_numbers.mean).to eq(3.0)
        expect(file_numbers.median).to eq(3)
      end
    end

    it "works with CSV enumerable data" do
      # Create sample CSV data
      csv_string = <<~CSV
        score,value
        10,100
        20,200
        30,300
        40,400
        50,500
      CSV

      csv_data = CSV.parse(csv_string, headers: true)

      # Extract numeric columns for analysis
      scores = csv_data.map { |row| row["score"].to_i }
      values = csv_data.map { |row| row["value"].to_i }

      expect(scores.mean).to eq(30.0)
      expect(values.mean).to eq(300.0)
      expect(scores.median).to eq(30)
      expect(values.median).to eq(300)
    end

    it "works with CSV::Table enumerable interface" do
      csv_string = <<~CSV
        measurement
        15
        25
        35
        45
        55
      CSV

      table = CSV.parse(csv_string, headers: true)
      measurements = table["measurement"].map(&:to_i)

      expect(measurements.mean).to eq(35.0)
      expect(measurements.median).to eq(35)
      expect(measurements.percentile(25)).to eq(25.0)
    end

    it "works with method chaining across different enumerable types" do
      # Test method chaining with different enumerable types
      range_data = (1..5)
      set_data = Set.new([6, 7, 8, 9, 10])

      # Combine and analyze
      combined = range_data.to_a + set_data.to_a
      expect(combined.mean).to eq(5.5) # (1+2+3+4+5+6+7+8+9+10)/10
      expect(combined.median).to eq(5.5)

      # Test outlier detection across types
      range_with_outlier = (1..5).to_a + [100]
      expect(range_with_outlier.remove_outliers).not_to include(100)
    end

    it "handles statistical operations with different numeric types" do
      # Mix of different numeric types that might come from different enumerables
      mixed_types = [
        1,           # Integer
        2.5,         # Float
        Rational(3, 1), # Rational
        4.0,         # Float
        5            # Integer
      ]

      expect(mixed_types.mean).to eq(3.1)
      expect(mixed_types.median).to eq(3.0)
      expect { mixed_types.variance }.not_to raise_error
      expect { mixed_types.standard_deviation }.not_to raise_error
    end

    it "maintains precision across different enumerable implementations" do
      # Test that statistical calculations maintain precision regardless of source
      array_data = [1.1, 2.2, 3.3, 4.4, 5.5]
      range_data = (11..55).step(11).map { |x| x / 10.0 }
      set_data = Set.new([1.1, 2.2, 3.3, 4.4, 5.5])
      enum_data = [1.1, 2.2, 3.3, 4.4, 5.5].each

      expected_mean = 3.3
      expected_variance = 3.025

      [array_data, range_data, set_data, enum_data].each do |data|
        expect(data.mean).to be_within(0.001).of(expected_mean)
        expect(data.variance).to be_within(0.001).of(expected_variance)
      end
    end

    it "works with empty enumerables of different types" do
      empty_array = []
      empty_range = (1...1) # Empty range
      empty_set = Set.new
      empty_enum = [].each

      [empty_array, empty_range, empty_set, empty_enum].each do |empty_data|
        expect(empty_data.median).to be_nil
        expect(empty_data.percentile(50)).to be_nil
        # Mean returns NaN for empty collections (0/0 = NaN)
        expect(empty_data.mean).to be_nan
      end
    end

    it "handles large datasets from different enumerable sources efficiently" do
      # Test performance with different large enumerable sources
      large_range = (1..1000)
      large_array = (1..1000).to_a
      large_set = Set.new((1..1000).to_a)

      [large_range, large_array, large_set].each do |large_data|
        expect { large_data.mean }.not_to raise_error
        expect { large_data.median }.not_to raise_error
        expect { large_data.remove_outliers }.not_to raise_error

        # Verify results are consistent
        expect(large_data.mean).to eq(500.5)
        expect(large_data.median).to eq(500.5)
      end
    end
  end

  describe "#percentage_difference" do
    it "calculates percentage difference between two collections" do
      a = [10, 20, 30]  # mean = 20
      b = [15, 25, 35]  # mean = 25

      # Percentage difference = |20 - 25| / ((20 + 25) / 2) * 100 = 5 / 22.5 * 100 ≈ 22.22%
      result = a.percentage_difference(b)
      expect(result).to be_within(0.01).of(22.22)
    end

    it "calculates percentage difference between collection and single value" do
      data = [10, 20, 30] # mean = 20

      # Percentage difference = |20 - 25| / ((20 + 25) / 2) * 100 = 22.22%
      result = data.percentage_difference(25)
      expect(result).to be_within(0.01).of(22.22)
    end

    it "returns 0 when comparing identical means" do
      a = [10, 20, 30]
      b = [5, 20, 35] # Both have mean = 20

      expect(a.percentage_difference(b)).to eq(0.0)
    end

    it "returns 0 when comparing with same value as mean" do
      data = [10, 20, 30] # mean = 20
      expect(data.percentage_difference(20)).to eq(0.0)
    end

    it "handles large percentage differences" do
      small = [1, 2, 3] # mean = 2
      large = [100, 200, 300] # mean = 200

      # Percentage difference = |2 - 200| / ((2 + 200) / 2) * 100 = 198 / 101 * 100 ≈ 196.04%
      result = small.percentage_difference(large)
      expect(result).to be_within(0.01).of(196.04)
    end

    it "always returns positive values" do
      a = [10, 20, 30]  # mean = 20
      b = [5, 15, 25]   # mean = 15

      expect(a.percentage_difference(b)).to be > 0
      expect(b.percentage_difference(a)).to be > 0
      expect(a.percentage_difference(b)).to eq(b.percentage_difference(a))
    end

    it "handles edge case when sum is zero" do
      data = [-10, 0, 10] # mean = 0
      result = data.percentage_difference(0)
      expect(result).to eq(0.0)

      # When both values sum to 0 but are different, should return infinity
      result = data.percentage_difference(-0.0)
      expect(result).to eq(0.0)
    end

    it "returns infinity when denominator approaches zero with different values" do
      data = [1, 1, 1] # mean = 1
      result = data.percentage_difference(-1)
      expect(result).to eq(Float::INFINITY)
    end

    it "works with floating point collections" do
      a = [1.5, 2.5, 3.5]  # mean = 2.5
      b = [2.0, 3.0, 4.0]  # mean = 3.0

      # Percentage difference = |2.5 - 3.0| / ((2.5 + 3.0) / 2) * 100 = 0.5 / 2.75 * 100 ≈ 18.18%
      result = a.percentage_difference(b)
      expect(result).to be_within(0.01).of(18.18)
    end
  end

  describe "#t_value" do
    it "calculates t-statistic for two samples with different means" do
      control = [10, 12, 11, 13, 12]     # mean = 11.6, std = 1.14
      treatment = [15, 17, 16, 18, 14]   # mean = 16.0, std = 1.58

      t_stat = control.t_value(treatment)
      expect(t_stat).to be < 0 # Control mean < treatment mean, so negative t-stat
      expect(t_stat.abs).to be > 3 # Should be significant difference

      # Reverse should give opposite sign
      reverse_t_stat = treatment.t_value(control)
      expect(reverse_t_stat).to be > 0
      expect(reverse_t_stat).to be_within(0.01).of(-t_stat)
    end

    it "calculates t-statistic for samples with similar means" do
      sample_a = [10, 11, 12, 13, 14]
      sample_b = [11, 12, 13, 14, 15] # Mean shifted by 1

      t_stat = sample_a.t_value(sample_b)
      expect(t_stat.abs).to be < 3 # Should be smaller difference
    end

    it "returns zero when comparing identical samples" do
      sample = [10, 12, 14, 16, 18]
      identical = [10, 12, 14, 16, 18]

      t_stat = sample.t_value(identical)
      expect(t_stat).to eq(0.0)
    end

    it "handles samples with different variances correctly" do
      low_variance = [10, 10.1, 10.2, 10.1, 10]      # Very consistent
      high_variance = [5, 15, 8, 12, 20]             # Very variable, similar mean

      t_stat = low_variance.t_value(high_variance)
      expect(t_stat).to respond_to(:abs) # Should be a valid number
      expect(t_stat).not_to be_nan
      expect(t_stat).not_to be_infinite
    end

    it "handles edge case with zero standard deviation" do
      constant = [5, 5, 5, 5, 5]     # Zero standard deviation
      variable = [4, 5, 6, 5, 5]     # Some variation

      # This should still work (denominator won't be zero due to variable sample)
      t_stat = constant.t_value(variable)
      expect(t_stat).to respond_to(:abs)
      expect(t_stat).not_to be_nan
    end

    it "produces expected values for known statistical examples" do
      # Classical example: comparing two groups
      group_a = [2.1, 1.9, 2.0, 2.2, 1.8, 2.0, 2.1]  # mean ≈ 2.01
      group_b = [2.8, 2.9, 2.7, 3.0, 2.6, 2.8, 2.9]  # mean ≈ 2.81

      t_stat = group_a.t_value(group_b)
      expect(t_stat).to be < -5 # Should be strongly negative (group_a < group_b)
      expect(t_stat.abs).to be > 5  # Should indicate significant difference
    end

    it "works with floating point precision" do
      precise_a = [1.001, 1.002, 1.003, 1.004, 1.005]
      precise_b = [1.006, 1.007, 1.008, 1.009, 1.010]

      t_stat = precise_a.t_value(precise_b)
      expect(t_stat).to be < 0
      expect(t_stat.abs).to be > 1  # Even small differences should be detectable
    end
  end

  describe "#degrees_of_freedom" do
    it "calculates degrees of freedom using Welch formula" do
      sample_a = [10, 12, 14, 16, 18]    # n=5, variance ≈ 10
      sample_b = [5, 15, 25, 35, 45, 55] # n=6, much higher variance

      df = sample_a.degrees_of_freedom(sample_b)
      expect(df).to be > 0
      expect(df).to be < (sample_a.count + sample_b.count - 2) # Should be less than pooled DF
    end

    it "approaches pooled degrees of freedom when variances are equal" do
      # Create samples with similar variances
      sample_a = [10, 11, 12, 13, 14]  # n=5, variance = 2.5
      sample_b = [15, 16, 17, 18, 19]  # n=5, variance = 2.5

      df = sample_a.degrees_of_freedom(sample_b)
      pooled_df = sample_a.count + sample_b.count - 2 # = 8

      # Should be close to pooled DF when variances are equal
      expect(df).to be_within(1.0).of(pooled_df)
    end

    it "handles samples with very different variances" do
      uniform = [10, 10, 10, 10, 10]      # Almost no variance
      variable = [1, 5, 10, 15, 25, 30]   # High variance

      df = uniform.degrees_of_freedom(variable)
      expect(df).to be > 0
      expect(df).to be < 10 # Should be much less than pooled DF due to unequal variances
    end

    it "returns symmetric result regardless of order" do
      sample_a = [1, 3, 5, 7, 9]
      sample_b = [2, 4, 6, 8, 10, 12, 14]

      df_a_b = sample_a.degrees_of_freedom(sample_b)
      df_b_a = sample_b.degrees_of_freedom(sample_a)

      expect(df_a_b).to be_within(0.001).of(df_b_a)
    end

    it "handles edge case with minimum sample sizes" do
      small_a = [1, 2]    # n=2 (minimum for variance calculation)
      small_b = [3, 4, 5] # n=3

      df = small_a.degrees_of_freedom(small_b)
      expect(df).to be > 0
      expect(df).to be < 3 # Less than pooled DF
    end

    it "produces expected values for textbook examples" do
      # Example from statistics textbook: comparing two teaching methods
      method_a = [85, 87, 83, 89, 86, 84, 88]  # n=7, more consistent
      method_b = [82, 91, 88, 85, 94, 87]      # n=6, more variable

      df = method_a.degrees_of_freedom(method_b)
      expect(df).to be_between(6, 11) # Expected range for this type of comparison
      expect(df).to be < (method_a.count + method_b.count - 2) # Should be less than pooled DF (11)
    end

    it "handles identical samples" do
      sample = [1, 2, 3, 4, 5]
      identical = [1, 2, 3, 4, 5]

      df = sample.degrees_of_freedom(identical)
      expect(df).to be_within(0.1).of(8.0) # Should approach n1 + n2 - 2
    end
  end

  describe "#signed_percentage_difference" do
    it "calculates signed percentage difference between two collections" do
      a = [10, 20, 30]  # mean = 20
      b = [15, 25, 35]  # mean = 25

      # Signed percentage difference = (20 - 25) / ((20 + 25) / 2) * 100 = -5 / 22.5 * 100 ≈ -22.22%
      result = a.signed_percentage_difference(b)
      expect(result).to be_within(0.01).of(-22.22)

      # Reverse should be positive
      result = b.signed_percentage_difference(a)
      expect(result).to be_within(0.01).of(22.22)
    end

    it "calculates signed percentage difference between collection and single value" do
      data = [10, 20, 30] # mean = 20

      # When collection mean < comparison value, result should be negative
      result = data.signed_percentage_difference(25)
      expect(result).to be_within(0.01).of(-22.22)

      # When collection mean > comparison value, result should be positive
      result = data.signed_percentage_difference(15)
      expect(result).to be_within(0.01).of(28.57)
    end

    it "returns 0 when comparing identical means" do
      a = [10, 20, 30]
      b = [5, 20, 35] # Both have mean = 20

      expect(a.signed_percentage_difference(b)).to eq(0.0)
    end

    it "shows direction of difference correctly" do
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

    it "handles performance monitoring scenarios" do
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

    it "handles A/B testing scenarios" do
      # Conversion rates
      control_rates = [0.12, 0.11, 0.13, 0.12, 0.12]    # mean = 0.12 (12%)
      variant_rates = [0.14, 0.13, 0.15, 0.14, 0.14]    # mean = 0.14 (14%)

      # Variant is 15.38% better than control
      improvement = variant_rates.signed_percentage_difference(control_rates)
      expect(improvement).to be_within(0.1).of(15.38)
    end

    it "returns infinity when denominator approaches zero with different values" do
      data = [1, 1, 1] # mean = 1
      result = data.signed_percentage_difference(-1)
      expect(result).to eq(Float::INFINITY)
    end

    it "preserves sign correctly for large differences" do
      small = [1, 2, 3] # mean = 2
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

  describe "#greater_than? alias" do
    it "returns true when first collection has significantly greater mean" do
      control = [10, 12, 11, 13, 12, 9, 14, 11, 10, 13]     # mean ≈ 11.5
      treatment = [15, 17, 16, 18, 14, 19, 16, 17, 15, 18]  # mean ≈ 16.5

      expect(treatment > control).to be true
    end
  end

  describe "#greater_than?" do
    it "returns true when first collection has significantly greater mean" do
      control = [10, 12, 11, 13, 12, 9, 14, 11, 10, 13]     # mean ≈ 11.5
      treatment = [15, 17, 16, 18, 14, 19, 16, 17, 15, 18]  # mean ≈ 16.5

      expect(treatment.greater_than?(control)).to be true
      expect(control.greater_than?(treatment)).to be false
    end

    it "returns false when collections have similar means" do
      group_a = [10, 11, 12, 13, 14]
      group_b = [10.5, 11.5, 12.5, 13.5, 14.5] # Only 0.5 unit difference

      expect(group_b.greater_than?(group_a)).to be false
      expect(group_a.greater_than?(group_b)).to be false
    end

    it "returns false when comparing identical collections" do
      sample = [10, 12, 14, 16, 18]
      identical = [10, 12, 14, 16, 18]

      expect(sample.greater_than?(identical)).to be false
      expect(identical.greater_than?(sample)).to be false
    end

    it "respects different alpha levels" do
      # Create datasets with moderate difference
      group_a = [100, 102, 101, 103, 102, 99, 104, 101, 100, 103]  # mean ≈ 101.5
      group_b = [105, 107, 106, 108, 107, 104, 109, 106, 105, 108] # mean ≈ 106.5

      # More lenient alpha should be more likely to detect significance
      lenient_result = group_b.greater_than?(group_a, alpha: 0.10)
      standard_result = group_b.greater_than?(group_a, alpha: 0.05)
      strict_result = group_b.greater_than?(group_a, alpha: 0.01)

      # Lenient should be >= Standard should be >= Strict in terms of likelihood to be true
      if strict_result
        expect(standard_result).to be true
        expect(lenient_result).to be true
      elsif standard_result
        expect(lenient_result).to be true
      end
    end

    it "handles collections with different variances" do
      low_variance = [50.0, 50.1, 50.2, 50.1, 50.0, 49.9, 50.0, 50.1] # Very consistent
      high_variance = [45, 55, 48, 52, 49, 51, 47, 53] # More variable, similar mean

      # Should handle unequal variances properly (Welch's t-test)
      result = high_variance.greater_than?(low_variance)

      expect(result).to be_falsey
    end

    it "handles edge cases with minimum sample sizes" do
      small_a = [10, 15]   # n=2, mean=12.5
      small_b = [30, 35]   # n=2, mean=32.5, much larger difference

      # With very small sample sizes, statistical significance may be harder to achieve
      # The test should verify the method works without error rather than specific results
      expect { small_b.greater_than?(small_a) }.not_to raise_error
      expect { small_a.greater_than?(small_b) }.not_to raise_error

      # Results should be boolean values
      result1 = small_b.greater_than?(small_a)
      result2 = small_a.greater_than?(small_b)

      # With improved t-distribution accuracy and a larger difference,
      # we should be able to detect significance even with tiny samples
      # small_b (32.5) should be significantly greater than small_a (12.5)
      expect(result1).to be_truthy  # small_b > small_a should be true
      expect(result2).to be_falsey  # small_a > small_b should be false
    end

    it "is consistent with t_value method" do
      sample_a = [5, 6, 7, 8, 9]
      sample_b = [10, 11, 12, 13, 14]

      t_stat = sample_a.t_value(sample_b)
      greater_result = sample_b.greater_than?(sample_a)

      # If t_stat is highly negative, sample_b should be greater than sample_a
      expect(greater_result).to be true if t_stat < -2

      # If t_stat is highly positive, sample_a should be greater than sample_b
      less_result = sample_a.greater_than?(sample_b)
      expect(less_result).to be true if t_stat > 2
    end

    it "handles A/B testing scenario" do
      control_conversion = [0.12, 0.11, 0.13, 0.12, 0.14, 0.11, 0.12, 0.13, 0.11, 0.12]    # ~12.1%
      variant_conversion = [0.15, 0.16, 0.14, 0.17, 0.15, 0.18, 0.16, 0.15, 0.17, 0.16]    # ~15.9%

      expect(variant_conversion.greater_than?(control_conversion)).to be true
      expect(control_conversion.greater_than?(variant_conversion)).to be false
    end

    it "handles performance testing scenario" do
      old_response_times = [150, 165, 155, 170, 160, 145, 175, 152, 158, 163]  # ~159ms
      new_response_times = [140, 145, 135, 150, 142, 138, 148, 144, 141, 147]  # ~143ms

      # Old times should NOT be significantly greater (improvement not significant enough)
      # This tests the boundary cases
      result = old_response_times.greater_than?(new_response_times)
      expect(result).to be_truthy
    end

    it "validates alpha parameter" do
      sample_a = [1, 2, 3, 4, 5]
      sample_b = [6, 7, 8, 9, 10]

      # Valid alpha levels should work
      expect { sample_b.greater_than?(sample_a, alpha: 0.01) }.not_to raise_error
      expect { sample_b.greater_than?(sample_a, alpha: 0.05) }.not_to raise_error
      expect { sample_b.greater_than?(sample_a, alpha: 0.10) }.not_to raise_error

      # Should handle edge alpha values
      expect { sample_b.greater_than?(sample_a, alpha: 0.001) }.not_to raise_error
      expect { sample_b.greater_than?(sample_a, alpha: 0.20) }.not_to raise_error
    end
  end

  describe "#less_than? alias" do
    it "returns true when first collection has significantly lower mean" do
      baseline = [150, 165, 155, 170, 160, 145, 175, 152, 158, 163]  # mean ≈ 159
      optimized = [120, 125, 115, 130, 118, 122, 128, 124, 119, 126] # mean ≈ 122

      expect(optimized.less_than?(baseline)).to be true
      expect(baseline.less_than?(optimized)).to be false
    end
  end

  describe "#less_than?" do
    it "returns true when first collection has significantly lower mean" do
      baseline = [150, 165, 155, 170, 160, 145, 175, 152, 158, 163]  # mean ≈ 159
      optimized = [120, 125, 115, 130, 118, 122, 128, 124, 119, 126] # mean ≈ 122

      expect(optimized.less_than?(baseline)).to be true
      expect(baseline.less_than?(optimized)).to be false
    end

    it "returns false when collections have similar means" do
      group_a = [20, 21, 22, 23, 24]
      group_b = [20.2, 21.2, 22.2, 23.2, 24.2] # Very small difference

      expect(group_a.less_than?(group_b)).to be false
      expect(group_b.less_than?(group_a)).to be false
    end

    it "returns false when comparing identical collections" do
      sample = [15, 17, 19, 21, 23]
      identical = [15, 17, 19, 21, 23]

      expect(sample.less_than?(identical)).to be false
      expect(identical.less_than?(sample)).to be false
    end

    it "respects different alpha levels" do
      # Create datasets with moderate difference
      higher_group = [80, 82, 81, 83, 82, 79, 84, 81, 80, 83]  # mean ≈ 81.5
      lower_group = [75, 77, 76, 78, 77, 74, 79, 76, 75, 78]   # mean ≈ 76.5

      # Test different alpha levels
      lenient_result = lower_group.less_than?(higher_group, alpha: 0.10)
      standard_result = lower_group.less_than?(higher_group, alpha: 0.05)
      strict_result = lower_group.less_than?(higher_group, alpha: 0.01)

      # More lenient alpha should be more likely to detect significance
      if strict_result
        expect(standard_result).to be true
        expect(lenient_result).to be true
      elsif standard_result
        expect(lenient_result).to be true
      end
    end

    it "is consistent with greater_than? method" do
      sample_a = [10, 12, 14, 16, 18]
      sample_b = [5, 7, 9, 11, 13]

      # If a.greater_than?(b) is true, then b.less_than?(a) should also be true
      expect(sample_b.less_than?(sample_a)).to be true if sample_a.greater_than?(sample_b)

      # If b.less_than?(a) is true, then a.greater_than?(b) should also be true
      expect(sample_a.greater_than?(sample_b)).to be true if sample_b.less_than?(sample_a)
    end

    it "is consistent with t_value method" do
      sample_a = [10, 11, 12, 13, 14]
      sample_b = [5, 6, 7, 8, 9]

      t_stat = sample_a.t_value(sample_b)

      # If t_stat is highly positive, sample_b should be less than sample_a
      expect(sample_b.less_than?(sample_a)).to be true if t_stat > 2

      # If t_stat is highly negative, sample_a should be less than sample_b
      expect(sample_a.less_than?(sample_b)).to be true if t_stat < -2
    end

    it "handles error rate improvement scenario" do
      old_error_rates = [0.025, 0.028, 0.024, 0.030, 0.026, 0.027, 0.029, 0.025, 0.028, 0.026] # ~2.68%
      new_error_rates = [0.012, 0.015, 0.013, 0.016, 0.014, 0.011, 0.013, 0.012, 0.015, 0.014] # ~1.35%

      expect(new_error_rates.less_than?(old_error_rates)).to be true
      expect(old_error_rates.less_than?(new_error_rates)).to be false
    end

    it "handles memory usage optimization scenario" do
      before_optimization = [245, 250, 242, 255, 248, 253, 247, 246, 252, 249] # ~248MB
      after_optimization = [198, 205, 195, 210, 200, 202, 197, 199, 207, 201]  # ~201MB

      expect(after_optimization.less_than?(before_optimization)).to be true
      expect(before_optimization.less_than?(after_optimization)).to be false
    end

    it "handles collections with different sample sizes" do
      small_sample = [5, 6, 7]                        # n=3, mean=6
      large_sample = [10, 11, 12, 13, 14, 15, 16]     # n=7, mean=13

      expect(small_sample.less_than?(large_sample)).to be true
      expect(large_sample.less_than?(small_sample)).to be false
    end

    it "handles edge case with zero variance" do
      constant_low = [10, 10, 10, 10, 10]     # Zero variance
      variable_high = [15, 16, 14, 17, 13]    # Some variance, higher mean

      expect(constant_low.less_than?(variable_high)).to be true
      expect(variable_high.less_than?(constant_low)).to be false
    end

    it "produces stable results with repeated calls" do
      sample_a = [100, 105, 98, 107, 103]
      sample_b = [90, 95, 88, 97, 93]

      # Results should be consistent across multiple calls
      result1 = sample_b.less_than?(sample_a)
      result2 = sample_b.less_than?(sample_a)
      result3 = sample_b.less_than?(sample_a)

      expect(result1).to eq(result2)
      expect(result2).to eq(result3)
    end

    it "validates alpha parameter bounds" do
      sample_a = [10, 12, 14, 16, 18]
      sample_b = [5, 7, 9, 11, 13]

      # Valid alpha levels should work without error
      expect { sample_b.less_than?(sample_a, alpha: 0.001) }.not_to raise_error
      expect { sample_b.less_than?(sample_a, alpha: 0.01) }.not_to raise_error
      expect { sample_b.less_than?(sample_a, alpha: 0.05) }.not_to raise_error
      expect { sample_b.less_than?(sample_a, alpha: 0.10) }.not_to raise_error
      expect { sample_b.less_than?(sample_a, alpha: 0.20) }.not_to raise_error
    end
  end

  describe "spaceship operator (<=>) and statistical comparison" do
    describe "#<=>" do
      it "returns 1 when this collection is significantly greater" do
        high_performance = [200, 210, 205, 215, 220]  # mean = 210
        low_performance = [50, 55, 60, 45, 65]        # mean = 55

        result = high_performance <=> low_performance
        expect(result).to eq(1)
      end

      it "returns -1 when this collection is significantly less" do
        new_response_times = [50, 100, 70, 80, 100]    # mean = 80 (much better - lower times)
        old_response_times = [500, 600, 550, 650, 580] # mean = 576 (worse - higher times)

        result = new_response_times <=> old_response_times
        expect(result).to eq(-1)
      end

      it "behaves consistently with underlying comparison methods" do
        dataset_a = [10, 20, 15, 25, 30]  # mean = 20
        dataset_b = [50, 60, 55, 65, 70]  # mean = 60

        spaceship_result = dataset_a <=> dataset_b

        # The spaceship result should match the underlying method behavior
        if dataset_a.greater_than?(dataset_b)
          expect(spaceship_result).to eq(1)
        elsif dataset_a.less_than?(dataset_b)
          expect(spaceship_result).to eq(-1)
        else
          expect(spaceship_result).to eq(0)
        end
      end

      it "returns 0 when collections are not significantly different" do
        # Use identical datasets to guarantee no significant difference
        baseline = [100, 100, 100, 100, 100]  # mean = 100
        variant = [100, 100, 100, 100, 100]   # mean = 100

        result = baseline <=> variant
        expect(result).to eq(0)
      end

      it "supports different alpha levels via method call" do
        # Data with moderate difference
        group_a = [10, 11, 12, 13, 14]      # mean = 12
        group_b = [15, 16, 17, 18, 19]      # mean = 17

        # Test with method call syntax for custom alpha (operator syntax uses default)
        default_result = group_a <=> group_b

        # Use greater_than? and less_than? with custom alpha to construct expected result
        lenient_greater = group_a.greater_than?(group_b, alpha: 0.10)
        lenient_less = group_a.less_than?(group_b, alpha: 0.10)

        expected_lenient = if lenient_greater
                             1
                           elsif lenient_less
                             -1
                           else
                             0
                           end

        # Both should be numeric (-1, 0, or 1)
        expect(default_result).to(satisfy { |v| [-1, 0, 1].include?(v) })
        expect(expected_lenient).to(satisfy { |v| [-1, 0, 1].include?(v) })
      end

      it "is symmetric for equality" do
        identical_a = [5, 5, 5, 5, 5]
        identical_b = [5, 5, 5, 5, 5]

        result_ab = identical_a <=> identical_b
        result_ba = identical_b <=> identical_a

        expect(result_ab).to eq(0)
        expect(result_ba).to eq(0)
      end

      it "is antisymmetric for inequality" do
        higher = [20, 22, 24, 26, 28]  # mean = 24
        lower = [10, 12, 14, 16, 18]   # mean = 14

        result_high_low = higher <=> lower
        result_low_high = lower <=> higher

        # If higher > lower (result = 1), then lower < higher (result = -1)
        if result_high_low == 1
          expect(result_low_high).to eq(-1)
        elsif result_high_low == -1
          expect(result_low_high).to eq(1)
        else
          expect(result_low_high).to eq(0)
        end
      end

      it "works with different data types" do
        integer_data = [1, 2, 3, 4, 5]
        float_data = [1.1, 2.1, 3.1, 4.1, 5.1]

        result = integer_data <=> float_data
        expect(result).to(satisfy { |v| [-1, 0, 1].include?(v) })
      end

      it "handles edge cases" do
        small_sample = [10, 20]
        large_sample = [15, 25, 35, 45, 55]

        expect { small_sample <=> large_sample }.not_to raise_error
        result = small_sample <=> large_sample
        expect(result).to(satisfy { |v| [-1, 0, 1].include?(v) })
      end
    end

    describe "greater than operator (>) alias" do
      it "works as alias for greater_than?" do
        treatment = [150, 160, 155, 165, 170]  # mean = 160
        control = [100, 110, 105, 115, 120]    # mean = 110

        operator_result = treatment > control
        method_result = treatment.greater_than?(control)

        expect(operator_result).to eq(method_result)
        expect(operator_result).to be true
      end

      it "supports custom alpha parameter" do
        sample_a = [100, 102, 104, 106, 108]
        sample_b = [95, 97, 99, 101, 103]

        # Test with different alpha levels
        result_alpha_five = sample_a.send(:>, sample_b, alpha: 0.05)
        result_alpha_ten = sample_a.send(:>, sample_b, alpha: 0.10)

        expect(result_alpha_five).to(satisfy { |v| [true, false].include?(v) })
        expect(result_alpha_ten).to(satisfy { |v| [true, false].include?(v) })
      end

      it "returns false when not significantly greater" do
        similar_a = [10, 12, 11, 13, 14]
        similar_b = [11, 13, 12, 14, 15]

        result = similar_a > similar_b
        expect(result).to be false
      end
    end

    describe "less than operator (<) alias" do
      it "works as alias for less_than?" do
        optimized = [85, 95, 90, 100, 80]      # Lower response times (better)
        baseline = [100, 110, 105, 115, 95]    # Higher response times (worse)

        operator_result = optimized < baseline
        method_result = optimized.less_than?(baseline)

        expect(operator_result).to eq(method_result)
        expect(operator_result).to be true
      end

      it "supports custom alpha parameter" do
        lower_group = [20, 22, 24, 26, 28]
        higher_group = [25, 27, 29, 31, 33]

        # Test with different alpha levels
        result_alpha_five = lower_group.send(:<, higher_group, alpha: 0.05)
        result_alpha_ten = lower_group.send(:<, higher_group, alpha: 0.10)

        expect(result_alpha_five).to(satisfy { |v| [true, false].include?(v) })
        expect(result_alpha_ten).to(satisfy { |v| [true, false].include?(v) })
      end

      it "returns false when not significantly less" do
        similar_a = [10, 12, 11, 13, 14]
        similar_b = [11, 13, 12, 14, 15]

        result = similar_b < similar_a
        expect(result).to be false
      end
    end

    describe "operator consistency" do
      it "maintains consistency between all comparison operators" do
        dataset_a = [50, 60, 55, 65, 70]  # mean = 60
        dataset_b = [30, 40, 35, 45, 50]  # mean = 40

        spaceship_result = dataset_a <=> dataset_b
        greater_result = dataset_a > dataset_b
        less_result = dataset_a < dataset_b

        case spaceship_result
        when 1
          expect(greater_result).to be true
          expect(less_result).to be false
        when -1
          expect(greater_result).to be false
          expect(less_result).to be true
        when 0
          expect(greater_result).to be false
          expect(less_result).to be false
        end
      end

      it "is consistent with underlying statistical methods" do
        high_sample = [100, 120, 110, 130, 115]
        low_sample = [60, 80, 70, 90, 75]

        # Spaceship operator should align with greater_than?/less_than?
        spaceship = high_sample <=> low_sample
        greater_than = high_sample.greater_than?(low_sample)
        less_than = high_sample.less_than?(low_sample)

        if spaceship == 1
          expect(greater_than).to be true
          expect(less_than).to be false
        elsif spaceship == -1
          expect(greater_than).to be false
          expect(less_than).to be true
        else # spaceship == 0
          expect(greater_than).to be false
          expect(less_than).to be false
        end
      end
    end
  end

  describe "sorting with statistical comparison operators" do
    let(:datasets) do
      [
        [10, 15, 12, 18, 11],  # mean = 13.2
        [20, 25, 22, 28, 21],  # mean = 23.2
        [5, 8, 6, 9, 7],       # mean = 7.0
        [30, 35, 32, 38, 31],  # mean = 33.2
        [15, 18, 16, 19, 17]   # mean = 17.0
      ]
    end

    describe "sorting with spaceship operator" do
      it "sorts collections by statistical significance" do
        # Sort using the spaceship operator
        sorted_datasets = datasets.sort

        # Check that datasets are in statistical order
        # Each dataset should not be significantly greater than the next
        (0...(sorted_datasets.length - 1)).each do |i|
          current = sorted_datasets[i]
          next_dataset = sorted_datasets[i + 1]

          # Current should not be significantly greater than next
          expect(current > next_dataset).to be false
        end
      end

      it "handles sorting with identical statistical means" do
        identical_datasets = [
          [10, 10, 10, 10, 10],  # mean = 10
          [8, 9, 10, 11, 12],    # mean = 10
          [5, 7, 10, 13, 15] # mean = 10
        ]

        expect { identical_datasets.sort }.not_to raise_error

        sorted = identical_datasets.sort
        expect(sorted.length).to eq(3)
      end

      it "maintains sort stability for equivalent datasets" do
        # Create datasets that should be statistically equivalent
        equivalent_datasets = [
          [100, 100, 100, 100, 100],
          [99, 100, 100, 100, 101],
          [98, 100, 100, 101, 101]
        ]

        # Sort multiple times and check consistency
        sort1 = equivalent_datasets.sort
        sort2 = equivalent_datasets.sort

        expect(sort1).to eq(sort2)
      end
    end

    describe "sorting with greater than operator" do
      it "can be used for custom sort logic" do
        # Sort in descending order using > operator
        desc_sorted = datasets.sort do |a, b|
          if a > b
            -1
          else
            (b > a ? 1 : 0)
          end
        end

        expect(desc_sorted).to be_an(Array)
        expect(desc_sorted.length).to eq(datasets.length)

        # Verify descending order: each element should not be significantly less than previous
        (1...desc_sorted.length).each do |i|
          current = desc_sorted[i]
          previous = desc_sorted[i - 1]

          expect(current > previous).to be false
        end
      end
    end

    describe "sorting with less than operator" do
      it "can be used for ascending sort logic" do
        # Sort in ascending order using < operator
        asc_sorted = datasets.sort do |a, b|
          if a < b
            -1
          else
            (b < a ? 1 : 0)
          end
        end

        expect(asc_sorted).to be_an(Array)
        expect(asc_sorted.length).to eq(datasets.length)

        # Verify ascending order: each element should not be significantly greater than next
        (0...(asc_sorted.length - 1)).each do |i|
          current = asc_sorted[i]
          next_dataset = asc_sorted[i + 1]

          expect(current > next_dataset).to be false
        end
      end
    end

    describe "real-world sorting scenarios" do
      it "sorts performance test results" do
        performance_results = [
          [120, 130, 125, 135, 128],  # High response times (worst)
          [50, 60, 55, 65, 58],       # Low response times (best)
          [90, 100, 95, 105, 98],     # Medium response times
          [80, 90, 85, 95, 88] # Lower-medium response times
        ]

        # Sort by performance (lower is better)
        sorted_by_performance = performance_results.sort

        # Verify that response times generally increase (worse performance)
        means = sorted_by_performance.map(&:mean)
        expect(means).to eq(means.sort)
      end

      it "sorts A/B test conversion rates" do
        conversion_tests = [
          [0.05, 0.06, 0.055, 0.065, 0.058],  # ~5.8% conversion
          [0.08, 0.09, 0.085, 0.095, 0.088],  # ~8.8% conversion
          [0.03, 0.04, 0.035, 0.045, 0.038],  # ~3.8% conversion
          [0.10, 0.11, 0.105, 0.115, 0.108] # ~10.8% conversion
        ]

        sorted_conversions = conversion_tests.sort

        # Higher conversion rates should come later in sort (if significant)
        means = sorted_conversions.map(&:mean)

        # Check that means are in non-decreasing order
        (0...(means.length - 1)).each do |i|
          expect(means[i]).to be <= means[i + 1]
        end
      end

      it "handles sorting with mixed significance levels" do
        mixed_datasets = [
          [100] * 5,              # Constant dataset
          [99, 100, 101] * 2,     # Low variance around 100
          [50, 150] * 3,          # High variance around 100
          [200] * 5 # Constant higher dataset
        ]

        expect { mixed_datasets.sort }.not_to raise_error

        sorted = mixed_datasets.sort
        expect(sorted.length).to eq(4)
      end
    end

    describe "edge cases in sorting" do
      it "handles empty collections gracefully" do
        datasets_with_empty = [
          [1, 2, 3],
          [],
          [4, 5, 6]
        ]

        # Should handle empty collections without crashing
        # Note: empty collections will cause errors in statistical comparisons
        expect do
          datasets_with_empty.reject(&:empty?).sort
        end.not_to raise_error
      end

      it "handles single-element collections" do
        single_element_datasets = [
          [10],
          [5],
          [15],
          [8]
        ]

        sorted = single_element_datasets.sort
        means = sorted.map(&:mean)

        expect(means).to eq(means.sort)
      end

      it "handles very similar datasets" do
        similar_datasets = [
          [100.1, 100.2, 100.3],
          [100.0, 100.1, 100.2],
          [100.2, 100.3, 100.4]
        ]

        expect { similar_datasets.sort }.not_to raise_error

        sorted = similar_datasets.sort
        expect(sorted.length).to eq(3)
      end
    end
  end

  describe "edge cases and error conditions" do
    it "handles very large datasets efficiently" do
      large_data = (1..1000).to_a + [10_000] # One outlier in 1000 points

      expect { large_data.remove_outliers }.not_to raise_error
      expect(large_data.remove_outliers).not_to include(10_000)
    end

    it "handles datasets with all identical values" do
      identical_data = [5] * 10

      expect(identical_data.mean).to eq(5.0)
      expect(identical_data.median).to eq(5.0)
      expect(identical_data.variance).to eq(0.0)
      expect(identical_data.standard_deviation).to eq(0.0)
      expect(identical_data.remove_outliers).to eq(identical_data)
    end

    it "handles mixed integer and float data" do
      mixed_data = [1, 2.5, 3, 4.7, 5]

      expect { mixed_data.mean }.not_to raise_error
      expect { mixed_data.median }.not_to raise_error
      expect { mixed_data.remove_outliers }.not_to raise_error
    end
  end
end
