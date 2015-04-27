# This will calculate confidence levels for a range of input values given a mean poisson distribution
require 'getoptlong'

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


opts = GetoptLong.new(
  ["--low", "-l",  	GetoptLong::OPTIONAL_ARGUMENT],
	["--high", "-h",	GetoptLong::OPTIONAL_ARGUMENT],
 	["--number", "-n",	GetoptLong::OPTIONAL_ARGUMENT],
  ["--mean","-m", GetoptLong::REQUIRED_ARGUMENT],
	["--verbose", "-v", 	GetoptLong::NO_ARGUMENT]
	)  
  

low_range = -1
high_range = -1
opt_verbose = false
mean = -1.0
opts.each do |opt,arg|
	if arg =~ /\S/ then puts "Option #{opt} is #{arg}" 
	else puts "Option #{opt} is true"
	end
	case opt 
		when "--low" 
			low_range = arg.to_i
		when "--high"
      if low_range<0 then
        puts "***ERROR -- Low value must be defined before high"
        raise
      end
			high_range = arg.to_i
		when "--number"
			low_range = arg.to_i
      high_range = arg.to_i
		when "--verbose"
			opt_verbose = true
    when "--mean"
      mean = arg.to_f
		else 
			print "***ERROR -- Illegal option #{opt}"
			raise 
		end
  end
if opt_verbose then puts "Low of range = #{low_range}    High of range = #{high_range}" end
prob_sum = 0
low_range.step(high_range,1) {|p_val|
  p = poisson(p_val,mean)
  if opt_verbose then puts "#{p_val}   #{mean}   #{p}" end
  prob_sum += p
}
puts
puts "Probability for mean #{mean}, low #{low_range}, high #{high_range} = #{prob_sum}"


