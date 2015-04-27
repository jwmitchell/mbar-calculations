# Program to analyze outages as a function of local wind speed as determined by publicly release 
# SDG&E outage data.
####
# Author: Joseph Mitchell
####
# 0.0    10/30/2011
# 1.0     12/11/2011  Excess plot 

######
# TO DO 
# - Excess for failure types
# - Add function for csv output
# - Add error bars to histograms
# - Find fit function (reverse Weibull?)


require 'getoptlong'
require 'Histogram'  # -I ../PowerLineFire
require 'win32ole'

###################
# Command line option parsing
# TBD

GUST = 1.6            # Estimated gust factor, based on SDG&E estimate in A.06-08-010

class Station  
  attr_reader :name,  :wind_hist, :type, :key, :gust_factor
  FIRST_DATA_ROW = 14  
  def initialize (w)   
    # Takes an argument of Excel worksheet object from DRI data summary.
    @gust_factor = 1.0
    @name = w.Range("A1").Value
    @key = w.Name[0..2]
    if @key[0,1] == "K" then
      @type = "nws"
      @gust_factor = GUST
    else @type = "raws" end
    @counts = Array.new(0)
    @wind_hist = Array.new(0)
    row = FIRST_DATA_ROW
    while !(w.Range("AA#{row}").Value.nil?) do
      @counts.push(w.Range("AA#{row}").Value)
      @wind_hist.push(w.Range("AB#{row}").Value)
      row += 1
    end 
    raise "ERROR - Station: Empty Station data for #{@name}." if @counts == 0
  end
  
  def Station.get_station_key(s)   
    #Takes any string and looks for station key, returning the first three characters
    key = s[0,3]
  end
  
  def bin_data(bin_size)
    @binned_hist = Array.new(@wind_hist.length)
    for mph in 0..@wind_hist.length do
      bin = bin_size * (1 + (mph / bin_size).to_int) - 1
      @binned_hist[mph] = @wind_hist[bin]
    end
  end
  
end

class Outages
  attr_writer :outages
  attr_reader :outages
 
  FIRST_DATA_ROW = 154
  
  def initialize(w)  # Takes argument of Excel worksheet object from SDG&E outage data
    row = FIRST_DATA_ROW
    @outages = Array.new(0)
    while !(w.Range("A#{row}").Value.nil?) do   #Assumes null cell ends array
      outage = Outage.new()
      outage.datetime = w.Range("A#{row}").Value
      outage.cause = w.Range("B#{row}").Value
      outage.equipment = w.Range("C#{row}").Value
      outage.gust = w.Range("D#{row}").Value
      outage.station = w.Range("H#{row}").Value
      @outages.push(outage)
      row += 1
    end
  end
  
end

class Outage
  attr_writer :gust, :datetime, :station, :cause, :equipment, :my_station
  attr_reader :gust, :datetime, :station, :cause, :equipment, :my_station
 
end
#################################

 WIND_BIN = 5
 DATA_FILE = "C:/Work/WEEDS/Calculations/PowerLineFire/SDGEWind/USGS_SDGE_outages.xls"
 
stations = Hash.new
outages = Array.new
causes = ["Undetermined","Wire","Pole","Vegetation"]

# The current outage file contains 1) a tab with a list of stations and the number of outages assigned to each
# 2) a tab with a list of outages (SDG&E data, converted to Excel by USGS), and 3) tabs for each of the RAWS and 
# airport wind histories. These station tabs are identified by 1) their four or five letter desginator, followed
# by an underscore, followed by the date range for the data set. 00_11, for instance would be 2000-2011.
# Data sets always begin on January 1 of the specified year and run until June 30 of 2011.

x1 = WIN32OLE.new("Excel.Application")
wkbk = x1.Workbooks.Open(DATA_FILE)
wksht = wkbk.Worksheets('Stations')
wksht.Range('A1:A10').columns.each {|col| col.cells.each {|cell| puts cell['Value']}}
n_wkshts = wkbk.Worksheets.Count
a_wks = Array.new(30)


for wks in wkbk.Worksheets
  puts wks.Name
 if (wks.Name != "Outages") && (wks.Name != "Stations") then
    hs = Hash.new
    st = Station.new(wks)
    st.bin_data(WIND_BIN)
    hs = {st.key => st}
    stations= stations.merge(hs)
  elsif wks.Name == "Outages" then
    outobj = Outages.new(wks)
    outages = outobj.outages
  end
end
wkbk.Close

hist_windspeeds = Histogram.new("Hourly wind gust speeds, all stations",0.0, 80.0, 80, 0.0, 1.0, 1)
hist_outages = Histogram.new("Wind gust speed at outage, all",0.0,80.0,80,0.0,1.0,1)
hist_windspeeds5 = Histogram.new("Hourly wind gust speeds, all stations",0.0, 80.0, 16, 0.0, 1.0, 1)
hist_outages5 = Histogram.new("Wind gust speed at outage, all",0.0,80.0,16,0.0,1.0,1)
hist_excess5 = Histogram.new("Excess over normal, all stations",0.0,80.0,16,0.0,1.0,1)
hist_excess5_2 = Histogram.new("Excess squared over normal, all stations",0.0,80.0,16,0.0,1.0,1)
hist_n5 = Histogram.new("Normalization histogram, all",0.0,80.0,16,0.0,1.0,1)
hist_outage_types = Hash.new
hist_outage_types5 = Hash.new
hist_excess_types5 = Hash.new
causes.each do |cause|
  hist_o = Histogram.new("Wind gust speed at outage, #{cause}",0.0,80.0,80,0.0,1.0,1)
  hist_o5 = Histogram.new("Wind gust speed at outage, #{cause}",0.0,80.0,16,0.0,1.0,1)
  hist_e5 = Histogram.new("Excess squared over normal, #{cause}",0.0,80.0,16,0.0,1.0,1)
  hist_outage_types[cause] = hist_o
  hist_outage_types5[cause] = hist_o5
  hist_excess_types5[cause] = hist_e5
end

outages.each do |outage|
  skey = Station.get_station_key(outage.station)
  station = stations[skey]
  next if station.nil?
  outage.my_station = station
  used_speed = outage.gust / station.gust_factor        #For RAWS use gust, for NWS use average wind speed.
  hist_outages.fill(used_speed,0.0,1.0)
  hist_outage_types[outage.cause].fill(used_speed,0.0,1.0)
  hist_outages5.fill(used_speed,0.0,1.0)
  hist_outage_types5[outage.cause].fill(used_speed,0.0,1.0)
  bin_gust5 = (outage.gust / 5.0).to_int                    # Determine what 5 mph bin the used wind speed falls into
  fraction_above_windspeed = 1.0 - station.wind_hist[bin_gust5*5 + 4]   # Fraction of gust data exceeding outage gust
  hist_excess5.fill(used_speed,0.0,fraction_above_windspeed)
  hist_excess5_2.fill(used_speed,0.0,fraction_above_windspeed**2)
  hist_excess_types5[outage.cause].fill(used_speed,0.0,fraction_above_windspeed)
  hist_n5.fill(used_speed,0.0,1.0)
end

# Normalize histograms
hist_excess = hist_excess5/hist_n5
hist_excess.title = "Fraction excess over 5 mph"

std_orig = $stdout
h_f = File.new("outages_all.csv", "w")
h_f5 = File.new("outages_all5.csv", "w")
h_e5 = File.new("excess_outage.csv", "w")
$stdout = h_f
hist_outages.out_csv_err
h_f.close
$stdout = h_f5
hist_outages5.out_csv_err
h_f5.close
$stdout = h_e5
hist_excess5.out_csv_err
h_e5.close

hist_outage_types.each do |cause, hist|
  h_f = File.new("outages_#{cause}.csv", "w")
  $stdout = h_f
  hist.out_csv_err
  h_f.close
end
hist_outage_types5.each do |cause, hist|
  h_f = File.new("outages_#{cause}5.csv", "w")
  $stdout = h_f
  hist.out_csv_err
  h_f.close
end
hist_excess_types5.each do |cause, hist|
  h_f = File.new("excess_#{cause}5.csv", "w")
  $stdout = h_f
  hist.out_csv_err
  h_f.close
end

$stdout = std_orig




