# Test program for MonteCarlo Ruby classes
#
require 'test/unit'
require 'MonteCarlo'


def test_mc_function0 (x)
  y = 1.0
  end

def test_mc_function1 (x)
  #  This is the fit of the power line fire distribution, valid between x of 2.0 and 5.2. x is the base 10 log of the fire size.
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

def test_mc_function2(r)
  # This is a poisson distribution, and must take integer rather than float arguments.
  fire_rate = 0.4
  poisson(r,fire_rate)
end

class TestMonteCarlo < Test::Unit::TestCase
	def test_create
		assert_nothing_raised()     { mc1 = MonteCarlo.new(method(:test_mc_function1), 2.0,5)}
	end
	
  def test_binning
		assert_nothing_raised()   {mc2 = MonteCarlo.new(method(:test_mc_function0), 0.0, 1.0)} 
    mc2 = MonteCarlo.new(method(:test_mc_function0), 0.0, 1.0)
    assert_equal(100,mc2.bins)
    assert_nothing_raised()   {mc2.set_bins(500)}
    assert_equal(500,mc2.bins)
    assert_equal(500,mc2.pvec.length)
  end
  
  def test_limits
    assert_raise(RuntimeError) {mc3 = MonteCarlo.new(method(:test_mc_function0), 10.0, 1.0)}
    mc3 = MonteCarlo.new(method(:test_mc_function0), 0, 10.0)
    assert_equal(0.0,mc3.low)
    assert_equal(10.0, mc3.high)
  end
    
  def test_mc_run
		assert_nothing_raised() {mc4 = MonteCarlo.new(method(:test_mc_function0), 0, 1)}
    mc4 = MonteCarlo.new(method(:test_mc_function0), 0.0, 1.0)
    assert_nothing_raised()  {mc4.load}
    mc4.load
    assert_in_delta(0.01,mc4.pvec[0],0.0000001)
    mc4.set_bins(1000)
    mc4.load
    assert_in_delta(0.001,mc4.pvec[0],0.0000001)
	end

  def test_mc_run0
    mc5 = MonteCarlo.new(method(:test_mc_function0), 0.0, 1.0)
    mc5.load
    assert_nothing_raised{mc5.run}
  end

  def test_mc_run1
    mc6 = MonteCarlo.new(method(:test_mc_function1), 2.0, 5.2)
    assert_nothing_raised{mc6.load}
    mc6.load
    assert_nothing_raised{mc6.run}
    assert_nothing_raised{(val,bin) = mc6.run}
    100.times { |i|
      (val, bin) = mc6.run
      assert_in_delta(3.6,val,1.6)
      assert_in_delta(50, bin, 50)
    }
  end
  
  def test_mc_int1                  # Test integer probability distributions (Poisson)
    assert_nothing_raised() {mc7 = MonteCarlo.new(method(:test_mc_function2), 0,5)}
    mc7 = MonteCarlo.new(method(:test_mc_function2), 0,5)
    assert_raise(RuntimeError) {mc7.load}
    assert_raise(RuntimeError) {mc7.set_int}
    mc7.set_bins(5) 
    assert_nothing_raised(RuntimeError) {mc7.set_int}
    mc7.set_int
    assert_nothing_raised() {mc7.load}
    mc7.load
    assert_nothing_raised() {mc7.run}
    mc7.run
  end

end

