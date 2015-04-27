# Test program for Power Line Fire MonteCarlo Ruby classes
#
require 'test/unit'
require 'MonteCarlo'
require 'PLFire_MonteCarlo'

def fire_size_distribution (x)
  #  This is the fit of the power line fire distribution, valid between x of 2.0 and 5.2. x is the base 10 log of the fire size in hectares
    a = -0.42
    b = 2.0
    y = 10**(a*x + b)
end

def factorial(i_val)
    fact = 1
    i_val.step(1,-1) {|f_val|
      fact *= f_val
      }
    return fact
end
  
def poisson(r, mu)  
  if !r.integer? then 
    puts "***ERROR - Poisson value r must be an integer"
    raise
  end
  p = (mu**r)*Math::exp(-mu)/factorial(r)
end

def mc_poisson(r)
  imctmp = InsuranceMonteCarlo.new()
  imctmp.read_data_file()       # This is a BAD implementation, but can find no other way to pass in info with one variable.
  tfire = Hash.new
  tfire = imctmp.get_fire_model()
  fire_rate = tfire["N_FIRES"].to_f/ tfire["YEARS_HISTORY"].to_f 
  poisson(r,fire_rate)
end

class TestPLFMonteCarlo < Test::Unit::TestCase
	def test_create
		assert_nothing_raised()     { mc1 = InsuranceMonteCarlo.new}
	end
	
  def test_read_data
    mc2 = InsuranceMonteCarlo.new
    assert_raise(RuntimeError) {mc2.read_data_file("doesntexist.dat")}     # Error if non-existent
    garbage = File.new("garbage.dat","w")
    garbage.print("This is so not good")
    garbage.close
    assert_raise(RuntimeError) {mc2.read_data_file("garbage.dat")}                     # Will find bad file format
    assert_nothing_raised() {mc2.read_data_file("insurance.dat")}            # Assumes insurance.dat is there
    mc2.read_data_file("insurance.dat")
    assert_equal(mc2.insurance_data["N_RUNS"].to_i, mc2.fire_model["N_RUNS"])
    assert_equal(mc2.insurance_data["MAX_UTILITY_M"].to_f   * 1000000.0, mc2.insurance_model["max_utility"])
  end
  
  def test_insurance_calculation
    # Test routine for calc_ins_cost (cost_sum)
    # Initialize test
    mc3 = InsuranceMonteCarlo.new
    mc3.read_data_file("insurance.dat")
    # Cost less than insurance deductible
    # No cost  - only premium
    
    delta = 100000.0
    minimal = 100000.0
    extreme = 100000000000.0
  
  
    cost = 0.0 
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(mc3.insurance_model["insurance_annual"], cost_u)           
    assert_equal(-mc3.insurance_model["insurance_annual"], cost_i)
    
    # Minimal Cost
    cost = minimal
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(cost+mc3.insurance_model["insurance_annual"], cost_u)               # All costs uninsured
    assert_equal(-mc3.insurance_model["insurance_annual"], cost_i)               # All costs uninsured
    assert_equal(cost, cost_i + cost_u)
    
    # Cost near deductible    
    cost = mc3.insurance_model["deductible_insurer"] - delta
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(cost+mc3.insurance_model["insurance_annual"], cost_u)               # All costs uninsured
    assert_equal(-mc3.insurance_model["insurance_annual"], cost_i)               # All costs uninsured
    assert_equal(cost, cost_i + cost_u)
    
    #Cost above deductible - Insurer pays, insured (possibly) co-pays.
     cost = mc3.insurance_model["deductible_insurer"] + delta
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(mc3.insurance_model["deductible_insurer"] +mc3.insurance_model["insurance_annual"] + delta*mc3.insurance_model["percent_util"], cost_u)               
    assert_equal(-mc3.insurance_model["insurance_annual"] + delta*(1.0-mc3.insurance_model["percent_util"]), cost_i)               
    assert_equal(cost, cost_i + cost_u)
     
    # Cost near insurance maximum, but less
    ins_costs =  mc3.insurance_model["max_insurer"] - delta
    unins_multiplier = mc3.insurance_model["percent_util"]/(1.0 - mc3.insurance_model["percent_util"])
    unins_costs = ins_costs*unins_multiplier + mc3.insurance_model["deductible_insurer"] 
    cost = unins_costs + ins_costs
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(mc3.insurance_model["insurance_annual"] + unins_costs, cost_u)
    assert_equal(-mc3.insurance_model["insurance_annual"] + ins_costs, cost_i) 
    assert_equal(cost, cost_i + cost_u)
    
    # Cost near insurance maximum, but greater
    ins_costs =  mc3.insurance_model["max_insurer"]
    unins_multiplier = mc3.insurance_model["percent_util"]/(1.0 - mc3.insurance_model["percent_util"])
    unins_costs = (mc3.insurance_model["max_insurer"])*unins_multiplier + mc3.insurance_model["deductible_insurer"] + delta
    cost = unins_costs + ins_costs
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    assert_equal(mc3.insurance_model["insurance_annual"] + unins_costs, cost_u)
    assert_equal(-mc3.insurance_model["insurance_annual"] + ins_costs, cost_i)           
    assert_equal(cost, cost_i + cost_u)
 
    # Very high costs
    cost = extreme
    (cost_u, cost_i) = mc3.calc_ins_costs(cost)
    unins_costs = extreme - mc3.insurance_model["max_insurer"] 
    assert_equal(mc3.insurance_model["insurance_annual"] + unins_costs, cost_u)
    assert_equal(-mc3.insurance_model["insurance_annual"] + mc3.insurance_model["max_insurer"], cost_i)           
    assert_equal(cost, cost_i + cost_u)
 
  end
  
  def test_weba_calculation
    # Test routine for calc_weba_cost (cost_sum)
    
    # Initialize test
    mc4 = InsuranceMonteCarlo.new
    mc4.read_data_file("insurance.dat")
  
    delta = 100000.0
    minimal = 100000.0
    extreme = 1000000000000.0
  
     # No cost
 
    cost = 0.0 
    assert_raise(RuntimeError) {(cost_u, cost_r) = mc4.calc_weba_costs(cost)}
    
    #Only premium
    cost = mc4.insurance_model["insurance_annual"]
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"], cost_u) #ERROR - remove ann. ins as profit.          
    assert_equal(mc4.insurance_model["weba_annual"] +mc4.insurance_model["insurance_annual"] , cost_r)
    assert_equal(cost, cost_r + cost_u) #ERROR!?!?!?
    
    # Costs slightly greater than premium
    cost = mc4.insurance_model["insurance_annual"] + delta
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + delta, cost_u)           
    assert_equal(mc4.insurance_model["weba_annual"] +mc4.insurance_model["insurance_annual"] , cost_r)
    assert_equal(cost, cost_r + cost_u)
     
    # Costs slightly less than WEBA deductible
     cost = mc4.insurance_model["insurance_annual"] + mc4.insurance_model["deductible_weba"] - delta
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"]+ mc4.insurance_model["deductible_weba"] - delta, cost_u)           
    assert_equal(mc4.insurance_model["weba_annual"] + mc4.insurance_model["insurance_annual"] , cost_r)
    assert_equal(cost, cost_r + cost_u)
    
    # Costs slightly more than WEBA deductible
     cost = mc4.insurance_model["insurance_annual"] + mc4.insurance_model["deductible_weba"] + delta
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["deductible_weba"], cost_u)           
    assert_equal(mc4.insurance_model["weba_annual"] + mc4.insurance_model["insurance_annual"]  + delta, cost_r)
    assert_equal(cost, cost_r + cost_u  )
    
    # Costs slightly less than WEBA copay threshold
     cost = mc4.insurance_model["insurance_annual"] + mc4.insurance_model["weba_copay_thresh"] - delta
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["deductible_weba"], cost_u)           
    assert_equal(mc4.insurance_model["weba_annual"]  + cost - mc4.insurance_model["deductible_weba"], cost_r)
    assert_equal(cost, cost_r + cost_u)
     
     # Costs slightly greater than WEBA copay threshold
     cost = mc4.insurance_model["insurance_annual"] + mc4.insurance_model["weba_copay_thresh"] + delta
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["deductible_weba"] + delta*mc4.insurance_model["percent_weba"], cost_u)           
    assert_equal(mc4.insurance_model["weba_annual"]  + mc4.insurance_model["insurance_annual"] + mc4.insurance_model["weba_copay_thresh"]  - mc4.insurance_model["deductible_weba"] + delta*(1.0 - mc4.insurance_model["percent_weba"]), cost_r)
    assert_equal(cost, cost_r + cost_u)

    # Costs slightly less than utility cap
    cost = -delta + mc4.insurance_model["insurance_annual"] + mc4.insurance_model["weba_copay_thresh"] + (mc4.insurance_model["max_utility"] - mc4.insurance_model["deductible_weba"])/mc4.insurance_model["percent_weba"]
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["max_utility"] - delta*mc4.insurance_model["percent_weba"], cost_u)           
    assert_equal(cost + delta + mc4.insurance_model["weba_annual"] - mc4.insurance_model["max_utility"] - delta*(1.0 - mc4.insurance_model["percent_weba"]), cost_r)
    assert_equal(cost, cost_r + cost_u)

    # Costs slightly greater than utility cap
    cost = delta + mc4.insurance_model["insurance_annual"] + mc4.insurance_model["weba_copay_thresh"] + (mc4.insurance_model["max_utility"] - mc4.insurance_model["deductible_weba"])/ mc4.insurance_model["percent_weba"]
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["max_utility"] , cost_u)           
    assert_equal(cost + mc4.insurance_model["weba_annual"] - mc4.insurance_model["max_utility"], cost_r)
    assert_equal(cost, cost_r + cost_u)
   
    # Extreme costs
    cost = extreme
    (cost_u, cost_r) = mc4.calc_weba_costs(cost)
    assert_equal(-mc4.insurance_model["weba_annual"] + mc4.insurance_model["max_utility"], cost_u)
    assert_equal(mc4.insurance_model["weba_annual"] + extreme - mc4.insurance_model["max_utility"], cost_r)
    assert_equal(cost, cost_r + cost_u)
    
  end

  
end

