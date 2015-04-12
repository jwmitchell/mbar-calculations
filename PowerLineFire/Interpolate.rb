# This is a set of libraries and executables designed to enable calculation
# of droplet trajectories. This is a more generalized form of the Perl 
# SprayThrow program, written in Ruby to make it more modular
#
# Version 1.0 - Created Interpolate class   	5/21/05
#
# Joseph W. Mitchell
# M-bar Technologies
# 
# Interpolate allows a list of x,y points to be read in from a file. The calc method then returns an interpolated y 
# value for a specified x. In version 1.0, this is a naive linear or log plot, and differentials are not taken. However,
# equal spacing between the reference points is not required.

class Interpolate
# The Interpolate class will initially support only linear interpolation using
# the framing datapoints. 
	private
	def scale(axis, value)
		if axis == "x" then iaxis = 0
		elsif axis == "y" then iaxis = 1
		else 
			raise "***ERROR - Axis value #{axis} must be x or y"
			return
		end
		case @mode[iaxis]
		when "lin"
			scale_value = value
		when "log"
			scale_value = Math::log(value)
		end
	end
	def descale(axis,value)
		if axis == "x" then iaxis = 0
		elsif axis == "y" then iaxis = 1
		else 
			raise "***ERROR - Axis value #{axis} must be x or y"
			return
		end
		case @mode[iaxis]
		when "lin"
			scale_value = value
		when "log"
			scale_value = Math::exp(value)
		end
	end
	
	public
	def initialize ( filename )
		#Todo - this can/should be generalized to an array input. 
		@interp_data = []
		@mode = ["lin","lin"]
		file_h = File.open(filename,"r")
	# The contents of the interpolation file must be 1) numeric 2) contain x,y pairs and 3) sequential
		i = 0
		interp_data_pts = [];
		while interp_data_str = file_h.gets 
			interp_data_pts = interp_data_str.split(/\s+/)
			@interp_data[i] = Array.new()
			if interp_data_pts.length > 2 then
				puts "***ERROR: Data point format is x  y, line #{i}"
				raise
			end
			j = 0
			interp_data_pts.each {|idp|  
				idp2num = idp.to_f
				if (idp2num == 0.0 && idp !~ /0/) then
					puts "***ERROR: Interpolation data of wrong type (#{idp2num})"
					raise
				end
				(@interp_data[i])[j] = idp.to_f
				j+=1
			}
			unless i == 0 then
				a = (@interp_data[i])[0]        
				b = (@interp_data[i-1])[0] 
				if  a <= b then
					puts "***ERROR: Non sequential data at line #{i}"
					raise
				end
			end
			i+=1
		end
	end
	
	def to_s 
		data_string = ""
		n_data_pts = @interp_data.length
		n_data_pts.times {|i|
			@interp_data[i].each { |data|
				data_string += data.to_s
				data_string += "  "
			}
			data_string += "\n"
		}
		return data_string
	end	
	
	def min
		@interp_data[0][0]
	end
	
	def max
		l = @interp_data.length
		@interp_data[l-1][0]
	end
	
	def set_mode (axis, modeid)
		if axis == "x" then iaxis = 0
		elsif axis == "y" then iaxis = 1
		else 
			puts "***ERROR - Axis value #{axis} must be x or y"
			raise
		end
		
		if modeid =~ /lin|log/ then 
			@mode[iaxis] = modeid
		else
			puts "***ERROR - illegal #{axis} mode #{modeid}"
			raise
		end
	end
	
	def calc(value)
		if value < self.min || value > self.max then
			raise "***ERROR - #{value} is outside the interpolation bounds (#{self.min} to #{self.max})"
		end
		low_x = 0; 		low_y = 0
		i = 0
		@interp_data.each {|data_pair|
			break if data_pair[0] > value 
			low_x = data_pair[0]
			low_y = data_pair[1]
			i += 1
		}
		high_x = @interp_data[i][0]
		high_y = @interp_data[i][1]
		
		x0 = scale("x",low_x)
		y0 = scale("y",low_y)
		x1 = scale("x",high_x)
		y1 = scale("y",high_y)
		x  = scale("x",value)
		
		y = y0 + (y1 - y0)*((x - x0)/(x1 - x0))
		descale("y",y)
	end	
end