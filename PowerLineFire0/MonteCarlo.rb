# MonteCarlo.rb
###########
# This program will generate a Monte Carlo using 1) numerical integration of
# an arbitrary source function, and 2) interpolation of the inverse.
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 0.1
# 5/20/2010
#######
# Usage
#

NBINS = 100


def mc_source_function (x) 
	a = -0.42
	b = 2.0
	y = 10**(a*x + b)
end

def mc_integrate(xlow, xhigh)
	integral = 0
	interval = xhigh - xlow
	delta = interval / NBINS
	diffprob = Array.new(NBINS)	
	NBINS.times { |i|
		x = xlow + (0.5 + i)*delta
		y = mc_source_function(x)
		integral = integral + y*delta
		puts "i = #{i}, x = #{x}  func = #{y} int = #{integral}"
		diffprob[i] = integral
	}
	NBINS.times { |i|
		diffprob[i] = diffprob[i] / integral
		puts "i = #{i}, diffprob = #{diffprob[i]}"
	}
	return diffprob
end

def mc_get_random_bin(pvec) #Generate a random value for specified prob array
	rval = rand
	i = 0
	while pvec[i] < rval do
		i = i+1
	end
	irand = i
        # Now interpolate over the interval to get the fractional change
	dely = (pvec[irand] - rval) / (pvec[irand+1] - pvec[irand])
	randx = i + dely
#	puts "  irand= #{irand}, dely= #{dely}, rx= #{randx}"
	return randx
end

def mc_interpolate(xlow, xhigh, bin, pvec)
	slope = (pvec[bin+1] - pvec[bin])/ delta	
end

def mc_random (low, high, xbin)
	xrand = (xbin/NBINS)*(high-low) + low
end

#puts "Value at 3 is #{mc_source_function(3.0)}, at 4 is #{mc_source_function(4.0)}";

prob_vec = mc_integrate(2.0,5.2)

5.times { |i|
	rand_i = mc_get_random_bin(prob_vec)
	rand_x = mc_random(2.0,5.2,rand_i)
	puts "Random = #{rand_i}   #{rand_x}"
}