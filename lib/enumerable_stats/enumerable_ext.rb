# frozen_string_literal: true

module EnumerableStats
  module EnumerableExt
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