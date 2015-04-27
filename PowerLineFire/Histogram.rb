# Histogram class is designed to bin (x,y) data.  
# v0.1 - The first version has simple fill, printout functions. 
class Histogram
	attr_reader :outside, :hist, :n_x_bins, :n_y_bins, :title, :count, :err
  attr_writer :title
	def initialize(title, x_lo, x_hi, n_x_bins, y_lo, y_hi, n_y_bins)
		if x_hi <= x_lo || y_hi <= y_lo then
			puts "ERROR - Upper end of range less than lower: X (#{x_lo}, #{x_hi}) Y (#{y_lo}, #{y_hi})"
			raise
		end
		if !(n_x_bins.integer?) || !(n_y_bins.integer?) then
			puts "ERROR - bin numbers need to be integers: #{n_x_bins}, #{n_y_bins}"
			raise
		end
		i = 0;          	j = 0
    @count = Array.new()                     # Total count for each bin
		@hist = Array.new()                        # Weighted values in each bin
    @err = Array.new()
		(0..(n_x_bins-1)).each do | i | 
			@hist[i] = Array.new()
      @count[i] = Array.new()
      @err[i] = Array.new()
			(0..(n_y_bins-1)).each do | j |
				@hist[i][j] = 0.0
        @count[i][j] = 0
        @err[i][j] = 0.0
			end
		end
		@x_lo = x_lo;  @x_hi = x_hi;   @n_x_bins = n_x_bins
		@y_lo = y_lo;  @y_hi = y_hi;   @n_y_bins = n_y_bins
		@bin_x = (@x_hi - @x_lo) / @n_x_bins
		@bin_y = (@y_hi - @y_lo) / @n_y_bins
    @title = title
		@outside = Array.new()
		(0..2).each do |i|
			@outside[i] = Array.new()
			(0..2).each do |j|
				@outside[i][j] = 0
			end
		end
	end
	
  def length
    n_x_bins
  end
  
  def fill(x, y, weight)
 		if (x < @x_lo) : x_out = 0                          # Check histogram bounds 
		elsif (x > @x_hi) : x_out = 2
		else x_out = 1
		end
		if (y < @y_lo) : y_out = 0
		elsif (y > @y_hi) : y_out = 2
		else y_out = 1
		end
		@outside[x_out][y_out] += 1
		unless (x_out == 1 && y_out == 1) then 
			return
		end
		# Unusual feature: interpret x or y as bin number if it is an integer. Otherwise calculate bin #.
		x_i = x.integer? ? x : get_xbin(x)
		y_i = y.integer? ? y : get_ybin(y)
		@hist[x_i][y_i] += weight
    @count[x_i][y_i] += 1
    @err[x_i][y_i]  = * @hist[x_i][y_i] / Math.sqrt(@count[x_i][y_i].to_f)
	end

  def fill_log(x_n, y_n, weight)
    if (x_n <= 0 || y_n <= 0) then
      return 
    end        # Log - does not fill for negative values
    x = Math.log10(x_n)
    y = Math.log10(y_n)
		if (x < @x_lo) : x_out = 0                          # Check histogram bounds 
		elsif (x > @x_hi) : x_out = 2
		else x_out = 1
		end
		if (y < @y_lo) : y_out = 0
		elsif (y > @y_hi) : y_out = 2
		else y_out = 1
		end
		@outside[x_out][y_out] += 1
		unless (x_out == 1 && y_out == 1) then 
			return
		end
		# Unusual feature: interpret x or y as bin number if it is an integer. Otherwise calculate bin #.
		x_i = x.integer? ? x : get_xbin(x)
		y_i = y.integer? ? y : get_ybin(y)
		@hist[x_i][y_i] += weight
    @count[x_i][y_i] += 1
 #   @err[x_i][y_i]  = @hist[x_i][y_i] / Math.sqrt(@count[x_i][y_i].to_f) 
	end
  
  def calc_err
    (0..(n_x_bins-1)).each do | i | 
			(0..(n_y_bins-1)).each do | j |
           @err[i][j]  = @hist[i][j] / Math.sqrt(@count[i][j].to_f) 
			end
    end
  end
  
	def get_xbin (x) 
		if (x < @x_lo) : nbin = -1
		elsif (x > @x_hi) : nbin = -999
		else
			nbin = (((x - @x_lo) / (@x_hi - @x_lo)) * @n_x_bins - 0.000001).to_int 
		end
	end
	
  def get_ybin (y) 
		if (y < @y_lo) : nbin =  -1
		elsif (y > @y_hi) : nbin = -999
		else
			nbin = (((y - @y_lo) / (@y_hi - @y_lo)) * @n_y_bins - 0.000001).to_int 
		end
	end
  
	def out_hist
		@hist.each {|histx|
			histx.each {|hist_val|
				print "#{hist_val}  "
			}
			print "\n"
		}
	end
  
  def out_csv
    # One dimension only
  xctr = 1.0
  @hist.each {|histx|
     histx.each {|hist_val|
      xbin = xctr*@bin_x
      print "#{xbin}, #{hist_val},"
    }
    xctr += 1.0
    print "\n"
  }
  end

  def out_csv_err
    # One dimension only
  xctr = 1.0
  calc_err
  @hist.each {|histx|
     histx.each {|hist_val|
      xbin = xctr*@bin_x
      print "#{xbin}, #{hist_val}, #{@err[(xctr-1).to_i]},"
    }
    xctr += 1.0
    print "\n"
  }
  end

  def out_array
    # One dimension only
    xctr = 1.0
    data_array = Array.new(@n_x_bins)
    bin_array = Array.new(@n_x_bins)
    hist_array = Array.new(3)
    for i in 0...@n_x_bins do
      bin_array[i] = (i+1)*@bin_x + @x_lo
      data_array[i] = @hist[i]
    end
    hist_array = [bin_array, data_array, @title]
  end

  def out_gpl
		xctr = 0.5
		yctr = 0.5
		@hist.each {|histx|
			histx.each {|hist_val|
				print "#{xctr}  #{yctr}  #{hist_val} \n"
				yctr += 1
			}
			yctr = 0.5
			xctr += 1
		}
	end
  
  def set_title(t)
    @title = t
  end
   
  def +(hist2)
    # Add 1D histograms
    raise ArgumentError, "Argument must be Histogram, is #{hist2.class}" if hist2.class.to_s != "Histogram"
    raise "Histograms must have equal bins: #{@n_x_bins} not equal to #{hist2.n_x_bins}" if @n_x_bins != hist2.n_x_bins
    hnew = Histogram.new(@title,@x_lo, @x_hi, @n_x_bins, @y_lo, @y_hi, @n_y_bins)
    for i in 0...@n_x_bins do
      if @hist[i][0].nil? : @hist[i][0] = 0 end
      if hist2.hist[i][0].nil? : hist2.hist[i][0] = 0.0 end
      hnew.hist[i][0] = @hist[i][0] + hist2.hist[i][0]
      hnew.count[i][0] = @count[i][0] + hist2.count[i][0]
 #     hnew.err[i][0] = (Math.sqrt(hnew.count[i][0].to_f) / hnew.count[i][0].to_f) * hnew.hist[i][0] 
     end
    return hnew
  end
  
  def /(hist2)
    # Divide 1D histograms
    raise ArgumentError, "Argument must be Histogram, is #{hist2.class}" if hist2.class.to_s != "Histogram"
    raise "Histograms must have equal bins: #{@n_x_bins} not equal to #{hist2.n_x_bins}."  if @n_x_bins != hist2.n_x_bins
    hnew = Histogram.new(@title,@x_lo, @x_hi, @n_x_bins, @y_lo, @y_hi, @n_y_bins)
    for i in 0...@n_x_bins do
      if @hist[i][0].nil? : @hist[i][0] = 0 end
      if hist2.hist[i][0] == 0 || hist2.hist[i][0].nil?
        if @hist[i][0] == 0 || @hist[i][0].nil?
          hnew.hist[i][0] =  0.0
        else
          raise "Histogram divide by zero, bin ##{i}"
        end
      else
        hnew.hist[i][0] = @hist[i][0] / hist2.hist[i][0]
        # Variance in division is given by quadrature. Effective count is quadrature of counts from both bins.
        # Assumes that the variance in the two historgrams is uncorrelated.
        hnew.count[i][0] = (Math.sqrt((@count[i][0]**2).to_f + (hist2.count[i][0]**2)).to_f).to_i   # Approximate and equivalent count.
      end
    end
    return hnew
  end
end
