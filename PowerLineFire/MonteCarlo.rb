# MonteCarlo.rb
###########
# This program will generate a Monte Carlo using 1) numerical integration of
# an arbitrary source function, and 2) interpolation of the inverse.
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 1.0
# 7/4/2010
# Fully working and tested generic Monte Carlo generator
#######
# Usage
# new(method :my_function, low, high) - initialize() function takes three parameters, the first being a method object which is the 
#      generator function for the Monte Carlo
# set_bins(bins) - allows the user to set the number of bins used in the Monte Carlo. Default is 100
# load - generates a probability histogram from the supplied function
# run - Runs the Monte Carlo. Returns a two-value array - the first being a function-weighted throw of the Monte Carlo, the second
#      being the corresponding histogram bin. 
#

class MonteCarlo
  @@NBINS = 100
  @pvec = Array.new(@@NBINS)     #Probability vector
  attr_reader :bins, :pvec, :low, :high
  
private 
 
  def initialize(mc_function, init_low, init_high)
    @mc_source_function= mc_function
    if (init_low >= init_high) then raise "***MonteCarlo::initialize: Usage is function, low range, high range" end
    @bins = @@NBINS
    @low = init_low
    @high = init_high
    @float = 0.5                                  #Default: Sample mid-bin for float variables
  end
  
  def mc_integrate(xlow, xhigh)
    # This Monte Carlo technique integrates the source function over the desired range and fills a vector
    # with the normalized contents. This vector is then used as the inverse function used to generate the Monte Carlo.
    
    integral = 0
    interval = xhigh - xlow
    delta = interval / @bins
    diffprob = Array.new(@bins)	
    @bins.times { |i|
      x = xlow + (@float + i)*delta
      y = @mc_source_function.call(x)
      integral = integral + y*delta
#      puts "i = #{i}, x = #{x}  func = #{y} int = #{integral}"
      diffprob[i] = integral
    }
    @bins.times { |i|
      diffprob[i] = diffprob[i] / integral
#      puts "i = #{i}, diffprob = #{diffprob[i]}"
    }
    return diffprob
  end

  def run      #Generate a random value for specified prob array
    rval = rand
    i = 0
    while @pvec[i] < rval do
      i = i+1
    end
    irand = i
        # Now interpolate over the interval to get the fractional change
    dely = (@pvec[irand] - rval) / (@pvec[irand+1] - @pvec[irand])
    randix = i - dely
    puts "  rand = #{rval} irand= #{irand}, dely= #{dely}, rx= #{randix}"
    xrand = (randix/@bins)*(high-low) + low
    return xrand, randix
  end

  def mc_interpolate(xlow, xhigh, bin)
    #Simple linear interpolation
    slope = (@pvec[bin+1] - @pvec[bin])/ delta	
  end

  def mc_random (low, high, xbin)
    xrand = (xbin/@bins)*(high-low) + low
  end

  #puts "Value at 3 is #{mc_source_function(3.0)}, at 4 is #{mc_source_function(4.0)}";

public

  def MonteCarlo.set_opts(opt_v, opt_d)
      @@opt_verbose = opt_v
      @@opt_debug = opt_d
  end

  def set_mc_distribution (mc_distribution_function)
    @mc_function = mc_distribution_function
  end
  
  def set_bins (newbins)
     @pvec = Array.new(newbins)     #Probability vector
     @bins = newbins
  end
  
  def set_int                                # Sample at bin boundary for integer distributions
    if (@bins != (@high - @low)) then
      puts "***MonteCarlo:set_int - Requires that number of bins be high-low"
      raise
    end
    @float = 0
  end

 def set_float                               # Sample mid bin for continuous distributions
    @float = 0.5
  end
 
  def load
    @pvec = mc_integrate(@low, @high)
  end

  def run      #Generate a random value for specified prob array
    rval = rand
    i = 0
    while @pvec[i] < rval do
      i = i+1
    end
    irand = i
        # Now interpolate over the interval to get the fractional change
    dely = (@pvec[irand] - rval) / (@pvec[irand] - @pvec[irand-1])
    randix = i - dely + 1
    xrand = (randix/@bins)*(high-low) + low
    if @@opt_debug 
      puts "MonteCarlo::  rand = #{rval} irand= #{irand}, dely= #{dely}, rx= #{randix}, x = #{xrand}"
    end
    return xrand, irand
  end

end
