# Program to analyze power line fire impacts and costs in Southern California using the WEBA model
# proposed by California utilities
####
# Author: Joseph Mitchell
#

require 'getoptlong'
require 'MonteCarlo'
require 'Histogram'

###################
# Command line option parsing
#

opts = GetoptLong.new(["--verbose", "-v",  GetoptLong::NO_ARGUMENT], 
                                 ["--debug", "-d",  GetoptLong::NO_ARGUMENT], 
                                 [ "--help",  "-h",   GetoptLong::NO_ARGUMENT ],
                                 ["--output", "-o", GetoptLong::OPTIONAL_ARGUMENT],
                                 ["--number", "-n", GetoptLong::OPTIONAL_ARGUMENT],
                                 ["--csv", "-c", GetoptLong::OPTIONAL_ARGUMENT],
                                 ["--file", "-f", GetoptLong::OPTIONAL_ARGUMENT])
opt_verbose = FALSE
opt_debug = FALSE
opt_datafile = "insurance.dat"
opt_outfile = "firedata"
opt_nruns = 0
opt_histogram_csv_file = "test_histograms.csv"

opts.each do |opt, arg|
  case opt
    when "--verbose"
      opt_verbose = TRUE
 
    when "--debug"
      opt_debug = TRUE
      opt_verbose = TRUE
 
    when  "--file"
      if arg == "": raise "***ERROR: PLFire_MonteCarlo: usage '-f <configuration data file>'" end
      opt_datafile = arg
    
    when "--output"
      if arg == "": raise "***ERROR: PLFire_MonteCarlo: usage '-o <output data file>'" end
      opt_outfile = arg
 
     when "--number"
      opt_nruns = arg.to_i

    when "--csv"
      opt_histogram_csv_file = arg

    when "--help"
      puts "Usage --verbose -v" 
      puts "      --debug -d"
      puts "      --help,  -h"
      puts "      --output -o <output data file>"
      puts "      --file -f <configuration data file>"
      puts "      --csv  -c <histogram csv file>"
      exit(0)
    end
  end
#######################


class InsuranceMonteCarlo
  
  attr_reader :insurance_data, :insurance_model, :fire_model
   
  def initialize
      @insurance_data = Hash.new
      @fire_model = Hash.new
      @insurance_model = Hash.new
  end
    
  def set_opts(opt_v, opt_d)
      @@opt_verbose = opt_v
      @@opt_debug = opt_d
  end
  
  def read_data_file (ins_file)
    raise "Missing insurance data file #{ins_file}" if !File.file?(ins_file)
    ins_data_file = File.new(ins_file)
    ins_parser = Regexp.new('(\w+)\s\=\s(\S+)[$\s]')
    while ll = ins_data_file.gets
      if @@opt_debug : puts ll end
      insdat = ins_parser.match(ll)
      raise "Insurance data format error: #{ll}" if insdat.nil?
      @insurance_data[$1] = $2
    end
    if @@opt_verbose 
      for data in @insurance_data.keys
        puts "#{data} = #{@insurance_data[data]}"
      end
    end
    set_fire_model()
    set_insurance_model()
  end 
  
    # Convert global fire data variables.
  def set_fire_model  
    @fire_model["N_RUNS"] = @insurance_data["N_RUNS"].to_i
    @fire_model["YEARS_HISTORY"] = @insurance_data["YEARS_HISTORY"].to_i
    @fire_model["YEARS_FUTURE"] = @insurance_data["YEARS_FUTURE"].to_i
    @fire_model["N_FIRES"] = @insurance_data["NFIRES"].to_i
    @fire_model["MIN_SIZE"] = @insurance_data["MIN_SIZE"].to_f
    @fire_model["MAX_SIZE"] = @insurance_data["MAX_SIZE"].to_f
    @fire_model["MAX_COST"] = @insurance_data["MAX_COST"].to_f
    @fire_model["WEIGHT"] = @insurance_data["WEIGHTING"].to_f
  end
  
  def set_insurance_model
    # Convert global insurance variables
    @insurance_model["deductible_insurer"] = @insurance_data["DED_INSURER_M"].to_f * 1000000.0
    @insurance_model["deductible_weba"] = @insurance_data["DED_WEBA_M"].to_f  * 1000000.0
    @insurance_model["max_insurer"] = @insurance_data["MAX_INSURER_M"].to_f  * 1000000.0
    @insurance_model["max_utility"] = @insurance_data["MAX_UTILITY_M"].to_f * 1000000.0
    @insurance_model["weba_copay_thresh"] = @insurance_data["THRESH_WEBA_COPAY_M"] .to_f  * 1000000.0
    @insurance_model["weba_annual"] = @insurance_data["COST_WEBA_ANNUAL"].to_f  * 1000000.0
    @insurance_model["insurance_annual"] = @insurance_data["COST_INSURANCE_ANNUAL"].to_f  * 1000000.0
    @insurance_model["percent_weba"] = @insurance_data["PERCENT_WEBA_COPAY"].to_f  / 100.0
    @insurance_model["percent_util"] = @insurance_data["PERCENT_UTILITY_COPAY"].to_f   / 100.0
    @insurance_model["max_utility"] = @insurance_data["MAX_UTILITY_M"].to_f   * 1000000.0    
  end

  def calc_ins_costs( cost_sum )       # NEED TO ADD PREMIUM
    # Assumes that insurance will always be applied before requesting WEBA reimbursement. 
    # Pass in the total fire costs and the insurance model 
    cost_ins = 0.0
    cost_unins = 0.0
  
    cost_ins = -@insurance_model["insurance_annual"]                      #Insurers receive annual premium, paid by utilities.
    cost_unins = @insurance_model["insurance_annual"]
    
    if (@insurance_model["percent_util"] == 1.0) then                  #TEST
      return cost_sum, 0.0
    end
    
    if (cost_sum < @insurance_model["deductible_insurer"] ) then    # Utilities pay up to the insurer deductible.
        cost_unins = cost_unins + cost_sum
    elsif (cost_sum < @insurance_model["max_insurer"] / (1.0 - @insurance_model["percent_util"]) + @insurance_model["deductible_insurer"])  then         #Between deductible and maximum insured  amount utilities pay copayment.
        cost_unins = cost_unins + @insurance_model["deductible_insurer"] + (cost_sum - @insurance_model["deductible_insurer"])*@insurance_model["percent_util"]
        cost_ins = cost_ins + (cost_sum - @insurance_model["deductible_insurer"])*(1.0 - @insurance_model["percent_util"])
    else                                                                            #Above insurance maximum, insurance pays maximum
        cost_unins = cost_unins + cost_sum - @insurance_model["max_insurer"]
        cost_ins = cost_ins + @insurance_model["max_insurer"]
    end  
    return cost_unins, cost_ins
  end

  def calc_weba_costs( cost_sum ) 
    #Divide up fire costs between ratepayers, insurers, and utilities
  
    raise "Utility cost #{cost_sum} must be greater than insurance premium #{@insurance_model["insurance_annual"]}" if (cost_sum < @insurance_model["insurance_annual"])
  
    cost_base =  @insurance_model["weba_annual"]
    cost_utils = -cost_base                                                          #Utilities receive reimbursement for insurance premium and their own risk premium
    cost_rps = cost_base + @insurance_model["insurance_annual"]
    cost_fires = cost_sum - @insurance_model["insurance_annual"]    # Remove insurance premium from fire costs
   
    if (cost_fires < @insurance_model["deductible_weba"] ) then       # Utilities pay up to the WEBA deductible
      cost_utils = cost_utils + cost_fires
    elsif (cost_fires <  @insurance_model["weba_copay_thresh"])        # Below the copay threshold, ratepayers pay all WEBA costs
      cost_utils = cost_utils + @insurance_model["deductible_weba"]
      cost_rps = cost_rps + cost_fires - @insurance_model["deductible_weba"]
    else                                                                                       # Utilities copay above the WEBA threshold. (Total cost or RP costs?)
      cost_utils = cost_utils + @insurance_model["deductible_weba"] + (cost_fires - @insurance_model["weba_copay_thresh"] )* @insurance_model["percent_weba"]
      cost_rps = cost_rps  + @insurance_model["weba_copay_thresh"] - @insurance_model["deductible_weba"] + (cost_fires - @insurance_model["weba_copay_thresh"]) * (1.0 - @insurance_model["percent_weba"])
    end 
  
    if (cost_utils > (@insurance_model["max_utility"] - @insurance_model["weba_annual"])) then                # Ratepayers pay all costs over the utility cap
      cost_utils = @insurance_model["max_utility"] - @insurance_model["weba_annual"]
      cost_rps =  @insurance_model["weba_annual"] + cost_sum  - @insurance_model["max_utility"]
    end
  
  return cost_utils, cost_rps
  
  end
end

public 

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

def mc_poisson(r)                                      # Note: The method passed into the Monte Carlo can vary in only one variable (one argument). This is why the data file needs to be re-read.
  imctmp = InsuranceMonteCarlo.new()
  imctmp.read_data_file("insurance.dat")       # This is a BAD implementation (hardcoded filename), but can find no other way to pass in info with one variable. Need a better scheme.
  fire_rate = imctmp.fire_model["WEIGHT"] * imctmp.fire_model["N_FIRES"].to_f / imctmp.fire_model["YEARS_HISTORY"].to_f 
  poisson(r,fire_rate)
end
#######

def array_tocsv(hist_array_list, csvfilename)
  # Utility array to pack multiple histograms into one csv file that can be then read in by Excel. Bins and data alternate columns.
  # TODO: Add histogram titles.
  
  if csvfilename == "" : csvfilename = "PLFire_histograms.csv" end
  
  csvfile = File.new(csvfilename, "w")
 
 # Find the maximum histogram size
  
  max_length = 0
  
#  array_data = Array.new(hist_array_list.length)
  array_data = Array.new
  array_hist = Array.new(3)
  
  hist_array_list.each { |hist|
    # Find the maximum histogram size
    if (hist.length > max_length) :
      max_length = hist.length
    end
    array_hist = hist.out_array
    array_data.push(array_hist)
  }
  
  puts "Longest histogram is #{max_length} long"
  
  # Write out the title string
  hist_string = ""
  array_data.each { |hist_set|
    hist_string = hist_string + hist_set[2]+ "," + hist_set[2] + ","
  }
  csvfile.puts hist_string
  
  max_length.times do |bin| 
    hist_string = "" 
    array_data.each { |hist_pair|
      if bin < hist_pair[0].length then
        hist_bin = hist_pair[0][bin]
        hist_val = hist_pair[1][bin]
      else
        hist_bin = ""
        hist_val = ""
      end
      hist_string = hist_string + hist_bin.to_s + "," + hist_val.to_s + ","
    }
    csvfile.puts hist_string
  end
  
end


#################

imc = InsuranceMonteCarlo.new
imc.set_opts(opt_verbose, opt_debug)
imc.read_data_file(opt_datafile)                 # TODO: Pass in as a path parameter, with default equal to ./insurance.dat

sum_cost_insurer = 0.0
sum_cost_ratepayer = 0.0
sum_cost_utility = 0.0

# Initialize output histograms

outfile_hist = opt_outfile + "_hist.csv"
opt_outfile = opt_outfile + ".dat"

hist_totalcost = Histogram.new("Total Cost", 0.0, 2.0E10,50,0.0,1.0,1)
hist_inscost = Histogram.new("Insurance Cost", 0.0, 2.0E10,50,0.0,1.0,1)
hist_utilcost = Histogram.new("Utility Cost", 0.0, 2.0E10,50,0.0,1.0,1)
hist_rpcost = Histogram.new("Ratepayer Cost", 0.0, 2.0E10,50,0.0,1.0,1)

hist_totallog = Histogram.new("Total Log", 6.0, 11.0,50,0.0,1.0,1)
hist_inslog = Histogram.new("Insurance Log", 6.0, 11.0,50,0.0,1.0,1)
hist_utillog = Histogram.new("Utility Log", 6.0, 11.0,50,0.0,1.0,1)
hist_rplog = Histogram.new("Ratepayer Log", 6.0, 11.0,50,0.0,1.0,1)

hist_insplus = Histogram.new("Insurer Profit", 0.0, 1.0E8,50,0.0,1.0,1)
hist_utilplus = Histogram.new("Utility Profit", 0.0, 1.0E8,50,0.0,1.0,1)

# Initialize Monte Carlo

MonteCarlo.set_opts(opt_verbose, opt_debug)

mc_fire_size = MonteCarlo.new(method(:fire_size_distribution), imc.fire_model["MIN_SIZE"], imc.fire_model["MAX_SIZE"])
mc_fire_size.load

mc_fires_per_year = MonteCarlo.new(method(:mc_poisson),0,5)
mc_fires_per_year.set_bins(5)
mc_fires_per_year.set_int
mc_fires_per_year.load
if opt_debug : puts "poisson: #{mc_fires_per_year.pvec}" end

fire_model = Hash.new
fire_model = imc.fire_model

if opt_nruns < 1  : opt_nruns = fire_model["N_RUNS"] end

fire_data_file = File.new(opt_outfile, "w")

fire_data_file.puts("Max cost, Total cost, Insurer, Utility, Ratepayer")
opt_nruns.times {
  cost_max = 0.0
  cost_sum = 0.0
  cost_total = 0.0

  cost_sum_ins = 0.0
  cost_sum_utils = 0.0
  cost_sum_rps = 0.0
  fire_model["YEARS_FUTURE"].times { |y|
    (x,n_fires) = mc_fires_per_year.run
    cost_sum = 0.0
    n_fires.times { |i|
    (size,sbin) = mc_fire_size.run
    fcost = 10**((fire_model["MAX_COST"] - fire_model["MAX_SIZE"]) + size)
    cost_sum = cost_sum + fcost
    cost_total = cost_total + fcost
      if fcost > cost_max : cost_max = fcost end
    }
    (cost_unins,cost_ins) = imc.calc_ins_costs(cost_sum)
    (cost_utils,cost_rps)  = imc.calc_weba_costs(cost_unins)
    cost_sum_ins = cost_sum_ins + cost_ins
    cost_sum_utils = cost_sum_utils + cost_utils
    cost_sum_rps = cost_sum_rps + cost_rps
    if opt_debug : puts " -- Insurance cost = #{cost_ins}   Utility cost = #{cost_utils}   Ratepayer cost = #{cost_rps}" end
  }
  if opt_verbose : puts "In #{fire_model['YEARS_FUTURE']} years: max fire cost = #{cost_max/1000000.0}M   total fire cost = #{cost_total/1000000.0}M" end
  if opt_verbose : puts "                   Insurance cost = #{cost_sum_ins/1000000.0}M   Utility cost = #{cost_sum_utils/1000000.0}M   Ratepayer cost = #{cost_sum_rps/1000000.0}M" end
  fire_data_file.puts("#{cost_max/1000000.0}, #{cost_total/1000000.0}, #{cost_sum_ins/1000000.0}, #{cost_sum_utils/1000000.0}, #{cost_sum_rps/1000000.0}")

  hist_totalcost.fill(cost_total, 1.0,1.0)
  hist_totallog.fill_log(cost_total, 1.0,1.0)
  hist_utilcost.fill(cost_sum_utils, 1.0,1.0)
  hist_utillog.fill_log(cost_sum_utils, 1.0,1.0)
  hist_inscost.fill(cost_sum_ins, 1.0,1.0)
  hist_inslog.fill_log(cost_sum_ins, 1.0,1.0)
  hist_rpcost.fill(cost_sum_rps, 1.0,1.0)
  hist_rplog.fill_log(cost_sum_rps, 1.0,1.0)
  
  if (cost_sum_ins < 0) : hist_insplus.fill(-cost_sum_ins, 1.0,1.0) end
  if (cost_sum_utils < 0) : 
    hist_utilplus.fill(-cost_sum_utils, 1.0,1.0) 
    if opt_verbose : puts "Util Profit = #{-cost_sum_utils}" end
  end

}
puts "Total Histogram"
hist_totalcost.out_csv
puts "Insured Histogram"
hist_inscost.out_csv

#hist_out_array = Array.new(2)
hist_out_array = [hist_totalcost, hist_totallog, hist_utilcost, hist_utillog, hist_inscost, hist_inslog, 
                        hist_rpcost, hist_rplog, hist_insplus, hist_utilplus]
array_tocsv(hist_out_array, opt_histogram_csv_file)



#hist_totalcost.out_gpl