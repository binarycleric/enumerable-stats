# frozen_string_literal: true

module EnumerableStats
  module EnumerableExt
    # Calculates the percentage difference between this collection's mean and another value or collection's mean
    # Uses the symmetric percentage difference formula: |a - b| / ((a + b) / 2) * 100
    # This is useful for comparing datasets or metrics where direction doesn't matter
    #
    # @param other [Numeric, Enumerable] Value or collection to compare against
    # @return [Float] Absolute percentage difference (always positive)
    def percentage_difference(other)
      a = mean.to_f
      b = other.respond_to?(:mean) ? other.mean.to_f : other.to_f

      return 0.0 if a == b
      return Float::INFINITY if a + b == 0

      ((a - b).abs / ((a + b) / 2.0).abs) * 100
    end

    # Calculates the signed percentage difference between this collection's mean and another value or collection's mean
    # Uses the signed percentage difference formula: (a - b) / ((a + b) / 2) * 100
    # Useful for performance comparisons where direction matters (e.g., improvements vs regressions)
    #
    # @param other [Numeric, Enumerable] Value or collection to compare against
    # @return [Float] Signed percentage difference (positive = this collection is higher, negative = other is higher)
    def signed_percentage_difference(other)
      a = mean.to_f
      b = other.respond_to?(:mean) ? other.mean.to_f : other.to_f

      return 0.0 if a == b
      return Float::INFINITY if a + b == 0

      ((a - b) / ((a + b) / 2.0).abs) * 100
    end

    # Calculates the t-statistic for comparing the means of two samples
    # Uses Welch's t-test formula which doesn't assume equal variances
    # A larger absolute t-value indicates a greater difference between sample means
    #
    # @param other [Enumerable] Another collection to compare against
    # @return [Float] The t-statistic value (can be positive or negative)
    # @example
    #   control = [10, 12, 11, 13, 12]
    #   treatment = [15, 17, 16, 18, 14]
    #   t_stat = control.t_value(treatment)  # => ~-4.2 (negative means treatment > control)
    def t_value(other)
      signal = (mean - other.mean)
      noise = Math.sqrt(
        ((standard_deviation**2) / count) +
          ((other.standard_deviation**2) / other.count)
      )

      (signal / noise)
    end

    # Calculates the degrees of freedom for comparing two samples using Welch's formula
    # This is used in statistical hypothesis testing when sample variances are unequal
    # The formula accounts for different sample sizes and variances between groups
    #
    # @param other [Enumerable] Another collection to compare against
    # @return [Float] Degrees of freedom for statistical testing
    # @example
    #   sample_a = [10, 12, 14, 16, 18]
    #   sample_b = [5, 15, 25, 35, 45, 55]
    #   df = sample_a.degrees_of_freedom(sample_b)  # => ~7.2
    def degrees_of_freedom(other)
      n1 = variance / count
      n2 = other.variance / other.count

      n = (n1 + n2)**2

      d1 = variance**2 / (count**2 * (count - 1))
      d2 = other.variance**2 / (other.count**2 * (other.count - 1))

      n / (d1 + d2)
    end

    # Calculates the arithmetic mean (average) of the collection
    #
    # @return [Float] The arithmetic mean of all numeric values
    # @example
    #   [1, 2, 3, 4, 5].mean  # => 3.0
    #   (1..10).mean          # => 5.5
    def mean
      sum / size.to_f
    end

    # Calculates the median (middle value) of the collection
    # For collections with an even number of elements, returns the average of the two middle values
    #
    # @return [Numeric, nil] The median value, or nil if the collection is empty
    # @example
    #   [1, 2, 3, 4, 5].median        # => 3
    #   [1, 2, 3, 4].median           # => 2.5
    #   [5, 1, 3, 2, 4].median        # => 3 (automatically sorts)
    #   [].median                     # => nil
    def median
      return nil if size == 0

      sorted = sort
      midpoint = size / 2

      if size.even?
        sorted[midpoint - 1, 2].sum / 2.0
      else
        sorted[midpoint]
      end
    end

    # Calculates the specified percentile of the collection
    # Uses linear interpolation between data points when the exact percentile falls between values
    # This is equivalent to the "linear" method used by many statistical software packages
    #
    # @param percentile [Numeric] The percentile to calculate (0-100)
    # @return [Numeric, nil] The value at the specified percentile, or nil if the collection is empty
    # @raise [ArgumentError] If percentile is not between 0 and 100
    # @example
    #   [1, 2, 3, 4, 5].percentile(50)    # => 3 (same as median)
    #   [1, 2, 3, 4, 5].percentile(25)    # => 2.0 (25th percentile)
    #   [1, 2, 3, 4, 5].percentile(75)    # => 4.0 (75th percentile)
    #   [1, 2, 3, 4, 5].percentile(0)     # => 1 (minimum value)
    #   [1, 2, 3, 4, 5].percentile(100)   # => 5 (maximum value)
    #   [].percentile(50)                 # => nil (empty collection)
    def percentile(percentile)
      return nil if size == 0

      unless percentile.is_a?(Numeric) && percentile >= 0 && percentile <= 100
        raise ArgumentError, "Percentile must be a number between 0 and 100, got #{percentile}"
      end

      sorted = sort

      # Handle edge cases
      return sorted.first if percentile == 0
      return sorted.last if percentile == 100

      # Calculate the position using the "linear" method (R-7/Excel method)
      # This is the most commonly used method in statistical software
      position = (size - 1) * (percentile / 100.0)

      # If position is an integer, return that exact element
      if position == position.floor
        sorted[position.to_i]
      else
        # Linear interpolation between the two surrounding values
        lower_index = position.floor
        upper_index = position.ceil
        weight = position - position.floor

        lower_value = sorted[lower_index]
        upper_value = sorted[upper_index]

        lower_value + weight * (upper_value - lower_value)
      end
    end

    # Calculates the sample variance of the collection
    # Uses the unbiased formula with n-1 degrees of freedom (Bessel's correction)
    #
    # @return [Float] The sample variance
    # @example
    #   [1, 2, 3, 4, 5].variance      # => 2.5
    #   [5, 5, 5, 5].variance         # => 0.0 (no variation)
    def variance
      mean = self.mean
      sum_of_squares = map { |r| (r - mean)**2 }.sum
      sum_of_squares / (count - 1).to_f
    end

    # Calculates the sample standard deviation of the collection
    # Returns the square root of the sample variance
    #
    # @return [Float] The sample standard deviation
    # @example
    #   [1, 2, 3, 4, 5].standard_deviation    # => 1.58
    #   [5, 5, 5, 5].standard_deviation       # => 0.0
    def standard_deviation
      Math.sqrt variance
    end

    # Removes extreme outliers using the IQR (Interquartile Range) method
    # This is particularly effective for performance data which often has
    # extreme values due to network issues, CPU scheduling, GC pauses, etc.
    #
    # @param multiplier [Float] IQR multiplier (1.5 is standard, 2.0 is more conservative)
    # @return [Array] Array with outliers removed
    def remove_outliers(multiplier: 1.5)
      return self if size < 4 # Need minimum data points for quartiles

      sorted = sort
      n = size

      # Use the standard quartile calculation with interpolation
      # Q1 position = (n-1) * 0.25
      # Q3 position = (n-1) * 0.75
      q1_pos = (n - 1) * 0.25
      q3_pos = (n - 1) * 0.75

      # Calculate Q1
      if q1_pos == q1_pos.floor
        q1 = sorted[q1_pos.to_i]
      else
        lower_index = q1_pos.floor
        upper_index = q1_pos.ceil
        weight = q1_pos - q1_pos.floor
        q1 = sorted[lower_index] + weight * (sorted[upper_index] - sorted[lower_index])
      end

      # Calculate Q3
      if q3_pos == q3_pos.floor
        q3 = sorted[q3_pos.to_i]
      else
        lower_index = q3_pos.floor
        upper_index = q3_pos.ceil
        weight = q3_pos - q3_pos.floor
        q3 = sorted[lower_index] + weight * (sorted[upper_index] - sorted[lower_index])
      end

      iqr = q3 - q1

      # Calculate bounds
      lower_bound = q1 - (multiplier * iqr)
      upper_bound = q3 + (multiplier * iqr)

      # Filter out outliers
      select { |value| value >= lower_bound && value <= upper_bound }
    end

    # Returns statistics about outlier removal for debugging/logging
    # Provides detailed information about how many outliers were removed and their percentage
    #
    # @param multiplier [Float] IQR multiplier for outlier detection (1.5 is standard, 2.0 is more conservative)
    # @return [Hash] Statistics hash containing :original_count, :filtered_count, :outliers_removed, :outlier_percentage
    # @example
    #   data = [1, 2, 3, 4, 5, 100]
    #   stats = data.outlier_stats
    #   # => {original_count: 6, filtered_count: 5, outliers_removed: 1, outlier_percentage: 16.67}
    def outlier_stats(multiplier: 1.5)
      original_count = size
      filtered = remove_outliers(multiplier: multiplier)

      {
        original_count: original_count,
        filtered_count: filtered.size,
        outliers_removed: original_count - filtered.size,
        outlier_percentage: ((original_count - filtered.size).to_f / original_count * 100).round(2)
      }
    end
  end
end