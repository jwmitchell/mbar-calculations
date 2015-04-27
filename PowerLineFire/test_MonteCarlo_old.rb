# Test program for MonteCarlo Ruby classes
#
require 'test/unit'
require 'MonteCarlo'

class TestMonteCarlo < Test::Unit::TestCase
	def test_create
		assert_nothing_raised()     { mc1 = MonteCarlo.new()}
	end
	
  def test_to_s
	end
	
  def test_mc_integrate
		assert_nothing_raised()   {mc2 = MonteCarlo.new()}
#		assert_equal(Interpolate.new("Interp_test0.dat").max, 4000.0)
	end
end

