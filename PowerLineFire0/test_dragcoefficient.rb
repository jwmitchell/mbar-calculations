require 'test/unit'
require 'dragcoefficient'

class TestDragcoefficient < Test::Unit::TestCase
	def test_run
    assert_nothing_raised()     { dc0 = dragcoefficient(1.0)}
    assert_raise(ArgumentError)     { dc1 = dragcoefficient("bogus")}
    assert_raise(Errno::EDOM)     { dc2 = dragcoefficient(-11.0)}
  end
  def test_series
    assert_nothing_raised() {
        -3.step(7.0,0.1) {|r|
          rn = 10**(r.to_f)
          cd = dragcoefficient(rn)
          puts "#{r}\t\t #{cd}"
          }
    }
  end
end