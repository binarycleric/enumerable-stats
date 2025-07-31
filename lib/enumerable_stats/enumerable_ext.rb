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

    def mean
      sum / size.to_f
    end

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

    def variance
      mean = self.mean
      sum_of_squares = map { |r| (r - mean)**2 }.sum
      sum_of_squares / (count - 1).to_f
    end

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