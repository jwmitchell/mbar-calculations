# fit_chi2.rb
###########
# This program allows a 1d vector to be fit to an arbitrary function by iterating and solving for a minimum chi squared.
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 0.1
# Oct. 4, 2008
#######
# Usage
#


def read_vector(filename)
  # This routine will read in the data vector from a file
  fn = File.new(filename,"r")
  rawvec = fn.readlines
  rvec = Array.new
  rawvec.each do |r|
    rvec.push(r.to_i)
  end
  rvec
end

def sigma(stat_vec)
  sig_vec = Array.new
  stat_vec.each do |v|
    sig_vec.push(Math.sqrt(v))
  end
  sig_vec
end

plf_vec = read_vector("plf_ha0.dat")
puts plf_vec
sig_vec = sigma(plf_vec)
puts sig_vec
