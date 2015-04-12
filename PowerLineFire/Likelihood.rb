# Likelihood for power line fires
################
# 

def factorial(n)
  if !n.integer? || n<0 : 
    raise "***ERROR - Likelihood::factorial - value #{n} is not a positive integer"
  end
  fact = 1
  if n > 1 then
    n.downto(2) { |n|
      fact = fact * n
    }
  end
  return fact
end

def poisson(mu,n_meas)
  if !n_meas.integer? || n_meas<0 : 
    raise "***ERROR - Likelihood::poisson - value #{n_meas} is not a positive integer"
  end
 p = (mu**n_meas * Math::exp(-mu))/factorial(n_meas)
end

def probobsv(median, mfrac)
  chi = median/2
  p = 1- (1 - chi)**mfrac
end

def loglikelihood(v_rmu)
  llp = 0.0
  v_rmu.each do |vm|
    r = vm[0]
    mu = vm[1]
    pois = poisson(r,mu)
    llp = llp + Math.log(pois)
  end
  return llp
end

class GenPoisson
  public
  
  def initialize(mymu)
    if (mymu < 0) then
      raise "***ERROR - Likelihood::genPoisson - your mean #{mymu} is less than zero"
    end
    @p_mu = Array.new()
    @gp_mu = mymu
    @p_mu.push(poisson(mymu,0)) 
    @psum = @p_mu[0]
  end
  
  def get_poisson
    nrand = rand
    l_psofar = @p_mu.length
    l_pois = 0
    if nrand < @p_mu[l_psofar-1] then 
      0.upto(l_psofar-1) do |pval|
        if nrand < @p_mu[pval] then
          return pval
        end
      end
    else
      while nrand > @psum  do
        l_pois = @p_mu.length
        @psum = @psum + poisson(@gp_mu,l_pois)
        @p_mu.push(@psum)
      end
      return l_pois
    end
  end
end



f = factorial(5) 
puts "The factorial of 5 is #{f}"
mmu = 4.8
tvec = []
gp = GenPoisson.new(mmu)
0.upto(10) do
  z = gp.get_poisson()
  puts "generated poisson = #{z}"
  pvec = [mmu,z]
  tvec.push(pvec)
end

llp = loglikelihood(tvec)
puts "Log likelihood is #{llp}"
