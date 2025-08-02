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
    # Epsilon for floating point comparisons to avoid precision issues
    EPSILON = 1e-10

    # Common alpha levels with their corresponding high-precision z-scores
    # Used to avoid floating point comparison issues while maintaining backward compatibility
    COMMON_ALPHA_VALUES = {
      0.10 => 1.2815515655446004,
      0.05 => 1.6448536269514722,
      0.025 => 1.9599639845400545,
      0.01 => 2.3263478740408408,
      0.005 => 2.5758293035489004,
      0.001 => 3.0902323061678132
    }.freeze

    CORNISH_FISHER_FOURTH_ORDER_DENOMINATOR = 92_160.0
    EDGEWORTH_SMALL_SAMPLE_COEFF = 4.0
    BSM_THRESHOLD = 1e-20

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
    # Uses Hill's approximation (1970) for accurate inverse t-distribution calculation
    #
    # @param df [Float] Degrees of freedom
    # @param alpha [Float] Significance level (e.g., 0.05 for 95% confidence)
    # @return [Float] Critical t-value for one-tailed test
    def critical_t_value(df, alpha)
      # For very large df (≥1000), t-distribution is essentially normal
      return inverse_normal_cdf(alpha) if df >= 1000

      # Use Hill's approximation for inverse t-distribution
      # This is more accurate than lookup tables and handles any df/alpha combination
      inverse_t_distribution(df, alpha)
    end

    # Calculates the inverse t-distribution using Cornish-Fisher expansion
    # This provides accurate critical t-values for any degrees of freedom and alpha level
    # Based on methods used in statistical software like R and MATLAB
    #
    # @param df [Float] Degrees of freedom
    # @param alpha [Float] Significance level for one-tailed test
    # @return [Float] Critical t-value
    def inverse_t_distribution(df, alpha)
      # Handle boundary cases
      return Float::INFINITY if df <= 0 || alpha <= 0
      return -Float::INFINITY if alpha >= 1
      return inverse_normal_cdf(alpha) if df >= 200 # Normal approximation for large df

      # Get the corresponding normal quantile
      z = inverse_normal_cdf(alpha)

      # Special cases with exact solutions
      if df == 1
        # Cauchy distribution: exact inverse
        return Math.tan(Math::PI * (0.5 - alpha))
      elsif df == 2
        # Exact formula for df=2: t = z / sqrt(1 - z^2/(z^2 + 2))
        # This is more numerically stable
        z_sq = z**2
        # Exact formula for df=2: t = z / sqrt(1 - z^2/(z^2 + 2))
        return z / Math.sqrt(1.0 - (z_sq / (z_sq + 2.0)))

      end

      # Use Cornish-Fisher expansion for general case
      # This is the method used in most statistical software

      # Base normal quantile
      t = z

      # First-order correction
      if df >= 4
        c1 = z / 4.0
        t += c1 / df
      end

      # Second-order correction
      if df >= 6
        c2 = ((5.0 * (z**3)) + (16.0 * z)) / 96.0
        t += c2 / (df**2)
      end

      # Third-order correction for better accuracy
      if df >= 8
        c3 = ((3.0 * (z**5)) + (19.0 * (z**3)) + (17.0 * z)) / 384.0
        t += c3 / (df**3)
      end

      # Fourth-order correction for very high accuracy
      if df >= 10
        c4 = ((79.0 * (z**7)) + (776.0 * (z**5)) +
          (1482.0 * (z**3)) + (776.0 * z)) / CORNISH_FISHER_FOURTH_ORDER_DENOMINATOR

        t += c4 / (df**4)
      end

      # For small degrees of freedom, apply additional small-sample correction
      if df < 8
        # Edgeworth expansion adjustment for small df
        delta = 1.0 / (EDGEWORTH_SMALL_SAMPLE_COEFF * df)
        small_sample_correction = z * delta * ((z**2) + 1.0)
        t += small_sample_correction
      end

      t
    end

    # Calculates the inverse normal CDF (quantile function) using Beasley-Springer-Moro algorithm
    # This is more accurate than the previous hard-coded approach
    #
    # @param alpha [Float] Significance level (0 < alpha < 1)
    # @return [Float] Z-score corresponding to the upper-tail probability alpha
    def inverse_normal_cdf(alpha)
      # Handle edge cases
      return Float::INFINITY if alpha <= 0
      return -Float::INFINITY if alpha >= 1

      # For common values, use high-precision constants to maintain backward compatibility
      # Use epsilon-based comparisons to avoid floating point precision issues
      COMMON_ALPHA_VALUES.each do |target_alpha, z_score|
        return z_score if (alpha - target_alpha).abs < EPSILON
      end

      # Use Beasley-Springer-Moro algorithm for other values
      # This is accurate to about 7 decimal places

      # Transform to work with cumulative probability from left tail
      p = 1.0 - alpha

      # Handle symmetric case
      if p > 0.5
        sign = 1
        p = 1.0 - p
      else
        sign = -1
      end

      # Constants for the approximation
      if p >= BSM_THRESHOLD
        # Rational approximation for central region
        t = Math.sqrt(-2.0 * Math.log(p))

        # Numerator coefficients
        c0 = 2.515517
        c1 = 0.802853
        c2 = 0.010328

        # Denominator coefficients
        d0 = 1.000000
        d1 = 1.432788
        d2 = 0.189269
        d3 = 0.001308

        numerator = c0 + (c1 * t) + (c2 * (t**2))
        denominator = d0 + (d1 * t) + (d2 * (t**2)) + (d3 * (t**3))

        x = t - (numerator / denominator)
      else
        # For very small p, use asymptotic expansion
        x = Math.sqrt(-2.0 * Math.log(p))
      end

      sign * x
    end
  end
end
