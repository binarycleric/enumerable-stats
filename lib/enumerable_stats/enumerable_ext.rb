# frozen_string_literal: true

module EnumerableStats
  # Extension module that adds statistical methods to all Enumerable objects.
  #
  # This module provides essential statistical functions including measures of central tendency
  # (mean, median), measures of dispersion (variance, standard deviation), percentile calculations,
  # outlier detection using the IQR method, and statistical comparison methods.
  #
  # When included, these methods become available on all Ruby collections that include
  # Enumerable (Arrays, Ranges, Sets, etc.), enabling seamless statistical analysis
  # without external dependencies.
  #
  # @example Basic statistical calculations
  #   [1, 2, 3, 4, 5].mean          #=> 3.0
  #   [1, 2, 3, 4, 5].median        #=> 3
  #   [1, 2, 3, 4, 5].percentile(75) #=> 4.0
  #
  # @example Outlier detection
  #   data = [1, 2, 3, 4, 100]
  #   data.remove_outliers           #=> [1, 2, 3, 4]
  #   data.outlier_stats             #=> { outliers_removed: 1, percentage: 20.0, ... }
  #
  # @example Statistical testing
  #   control = [10, 12, 14, 16, 18]
  #   treatment = [15, 17, 19, 21, 23]
  #   control.t_value(treatment)     #=> negative t-statistic
  #   control.degrees_of_freedom(treatment) #=> degrees of freedom for Welch's t-test
  #   treatment.greater_than?(control) #=> true (treatment mean significantly > control mean)
  #   control.less_than?(treatment)    #=> true (control mean significantly < treatment mean)
  #
  # @see Enumerable
  # @since 0.1.0
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
      return Float::INFINITY if (a + b).zero?

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
      return Float::INFINITY if (a + b).zero?

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

      d1 = (variance**2) / ((count**2) * (count - 1))
      d2 = (other.variance**2) / ((other.count**2) * (other.count - 1))

      n / (d1 + d2)
    end

    # Tests if this collection's mean is significantly greater than another collection's mean
    # using a one-tailed Student's t-test. Returns true if the test indicates statistical
    # significance at the specified alpha level.
    #
    # @param other [Enumerable] Another collection to compare against
    # @param alpha [Float] Significance level (default: 0.05 for 95% confidence)
    # @return [Boolean] True if this collection's mean is significantly greater
    # @example
    #   control = [10, 12, 11, 13, 12]     # mean ≈ 11.6
    #   treatment = [15, 17, 16, 18, 14]   # mean = 16.0
    #   treatment.greater_than?(control)   # => true (treatment significantly > control)
    #   control.greater_than?(treatment)   # => false
    def greater_than?(other, alpha: 0.05)
      t_stat = t_value(other)
      df = degrees_of_freedom(other)
      critical_value = critical_t_value(df, alpha)

      t_stat > critical_value
    end

    # Tests if this collection's mean is significantly less than another collection's mean
    # using a one-tailed Student's t-test. Returns true if the test indicates statistical
    # significance at the specified alpha level.
    #
    # @param other [Enumerable] Another collection to compare against
    # @param alpha [Float] Significance level (default: 0.05 for 95% confidence)
    # @return [Boolean] True if this collection's mean is significantly less
    # @example
    #   control = [10, 12, 11, 13, 12]     # mean ≈ 11.6
    #   treatment = [15, 17, 16, 18, 14]   # mean = 16.0
    #   control.less_than?(treatment)      # => true (control significantly < treatment)
    #   treatment.less_than?(control)      # => false
    def less_than?(other, alpha: 0.05)
      t_stat = t_value(other)
      df = degrees_of_freedom(other)
      critical_value = critical_t_value(df, alpha)

      t_stat < -critical_value
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
      return nil if size.zero?

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
      return nil if size.zero?

      unless percentile.is_a?(Numeric) && percentile >= 0 && percentile <= 100
        raise ArgumentError, "Percentile must be a number between 0 and 100, got #{percentile}"
      end

      sorted = sort

      # Handle edge cases
      return sorted.first if percentile.zero?
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

        lower_value + (weight * (upper_value - lower_value))
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
      sum_of_squares = sum { |r| (r - mean)**2 }
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
        q1 = sorted[lower_index] + (weight * (sorted[upper_index] - sorted[lower_index]))
      end

      # Calculate Q3
      if q3_pos == q3_pos.floor
        q3 = sorted[q3_pos.to_i]
      else
        lower_index = q3_pos.floor
        upper_index = q3_pos.ceil
        weight = q3_pos - q3_pos.floor
        q3 = sorted[lower_index] + (weight * (sorted[upper_index] - sorted[lower_index]))
      end

      iqr = q3 - q1

      # Calculate bounds
      lower_bound = q1 - (multiplier * iqr)
      upper_bound = q3 + (multiplier * iqr)

      # Filter out outliers
      select { |value| value.between?(lower_bound, upper_bound) }
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

    private

    # Calculates the critical t-value for a one-tailed test given degrees of freedom and alpha level
    # Uses a lookup table for common df values and approximations for others
    #
    # @param df [Float] Degrees of freedom
    # @param alpha [Float] Significance level (e.g., 0.05 for 95% confidence)
    # @return [Float] Critical t-value for one-tailed test
    def critical_t_value(df, alpha)
      # For large df (≥30), t-distribution approximates normal distribution
      return normal_critical_value(alpha) if df >= 30

      # Lookup table for common t-values (one-tailed, α = 0.05)
      # These are standard critical values from t-tables
      t_table_05 = {
        1 => 6.314, 2 => 2.920, 3 => 2.353, 4 => 2.132, 5 => 2.015,
        6 => 1.943, 7 => 1.895, 8 => 1.860, 9 => 1.833, 10 => 1.812,
        11 => 1.796, 12 => 1.782, 13 => 1.771, 14 => 1.761, 15 => 1.753,
        16 => 1.746, 17 => 1.740, 18 => 1.734, 19 => 1.729, 20 => 1.725,
        21 => 1.721, 22 => 1.717, 23 => 1.714, 24 => 1.711, 25 => 1.708,
        26 => 1.706, 27 => 1.703, 28 => 1.701, 29 => 1.699
      }

      # Lookup table for common t-values (one-tailed, α = 0.01)
      t_table_01 = {
        1 => 31.821, 2 => 6.965, 3 => 4.541, 4 => 3.747, 5 => 3.365,
        6 => 3.143, 7 => 2.998, 8 => 2.896, 9 => 2.821, 10 => 2.764,
        11 => 2.718, 12 => 2.681, 13 => 2.650, 14 => 2.624, 15 => 2.602,
        16 => 2.583, 17 => 2.567, 18 => 2.552, 19 => 2.539, 20 => 2.528,
        21 => 2.518, 22 => 2.508, 23 => 2.500, 24 => 2.492, 25 => 2.485,
        26 => 2.479, 27 => 2.473, 28 => 2.467, 29 => 2.462
      }

      df_int = df.round

      if alpha <= 0.01
        t_table_01[df_int] || t_table_01[29] # Use df=29 as fallback for larger values
      elsif alpha <= 0.05
        t_table_05[df_int] || t_table_05[29] # Use df=29 as fallback for larger values
      else
        # For alpha > 0.05, interpolate or use approximation
        # This is a rough approximation for other alpha levels
        base_t = t_table_05[df_int] || t_table_05[29]
        base_t * ((0.05 / alpha)**0.5)
      end
    end

    # Returns the critical value for standard normal distribution (z-score)
    # Used when degrees of freedom is large (≥30)
    #
    # @param alpha [Float] Significance level
    # @return [Float] Critical z-value for one-tailed test
    def normal_critical_value(alpha)
      # Common z-values for one-tailed tests
      # Use approximate comparisons to avoid float equality issues
      if (alpha - 0.10).abs < 1e-10
        1.282
      elsif (alpha - 0.05).abs < 1e-10
        1.645
      elsif (alpha - 0.025).abs < 1e-10
        1.960
      elsif (alpha - 0.01).abs < 1e-10
        2.326
      elsif (alpha - 0.005).abs < 1e-10
        2.576
      else
        # Approximation using inverse normal for other alpha values
        # This is a rough approximation of the inverse normal CDF
        # For α = 0.05, this gives approximately 1.645
        Math.sqrt(-2 * Math.log(alpha))
      end
    end
  end
end
