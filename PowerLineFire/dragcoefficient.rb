# dragcoefficient.rb
###########
# This program will calculate the drag coefficient given the Reynolds number, as per # Clift, Grace, and Weber, Table 5.2 (p. 112)
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 0.1
# Jan 6, 2007
#######
# Usage
#
# A simple calculator that selects the proper equation for calculating drag coefficient as a function of the Reynolds number provided.
# Simply enter Reynolds number and out comes the drag coefficient.


def dragcoefficient (reynolds)
  w = Math.log10(reynolds)
  cd = case
      when reynolds < 0.01 : 3.0/16.0 + 24.0/reynolds
      when (reynolds >= 0.01) && (reynolds < 20.0) : (24.0/reynolds)*(1.0+0.1315*reynolds**(0.82-0.05*w))
      when (reynolds >= 20.0) && (reynolds < 260.0) : (24.0/reynolds)*(1.0+0.1935*reynolds**0.6305)
      when (reynolds >= 260.0) && (reynolds < 1500.0) : 10**(1.6453 - 1.1242*w + 0.1558*w**2)
      when (reynolds >= 1.500) && (reynolds < 1.2E4) : 10**(-2.4571 + 2.5558*w - 0.9295*w**2 +0.1049*w**3)
      when (reynolds >= 1.2E4) && (reynolds < 4.4E4) : 10**(-1.9181 + 0.6370*w - 0.0636*w**2)
      when (reynolds >= 4.4E4) && (reynolds < 3.38E5) : 10**(-4.3390 + 1.5809*w - 0.1546*w**2)
      when (reynolds >= 3.38E5) && (reynolds <4.0E5) : 29.79 - 5.3*w
      when (reynolds >= 4.0E5) && (reynolds <1.0E6) : 0.1*w -0.49
      when (reynolds >= 1.0E6) : 0.19 - 8.0E4/reynolds
      when (reynolds < 0.0) : raise "Reynolds number must be positive definite"
      else raise "Unrecognized Reynolds number format: #{reynolds}"
  end
      
    
end

