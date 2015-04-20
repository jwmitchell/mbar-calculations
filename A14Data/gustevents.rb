require_relative 'mesomax'
require 'roo'

DEBUG=2
EVENTS=24
STATIONS=8
EVENTROW0=3
DATECOL='B'
STATIONROW=2
STATIONCOL0=9
DURCOL = 'E'
SHEET = "WeatherIncidents"

##################
# This version will scan several RAWS stations at known times of fire weather
# between 2005 and 2015. 


excel_data_file = Roo::Excelx.new('MGRA-DR3-66-Mbar.xlsx')

mxg_file = File.new('FWG_0515.dat','w')

stationcolmax = STATIONCOL0 + STATIONS
rowmax = EVENTROW0 + EVENTS

for stidx in (STATIONCOL0..stationcolmax) do
  station = excel_data_file.cell(STATIONROW,stidx,SHEET)
  if DEBUG>0 then puts "Station = #{station}" end
  mxg_file.puts(station)
  
  for evt in (EVENTROW0...rowmax) do
    d0 = excel_data_file.cell(evt,DATECOL,SHEET)
    dt = d0.to_datetime + 1
    days = excel_data_file.cell(evt,DURCOL,SHEET)
    maxgust = 0.0
    for day in (1..days) do
      if DEBUG>1 then puts "Checking date #{dt}" end
      mesodat = MesoMax.new(dt,station)
      mesodat.dont_fail_on_empty
      gust = mesodat.max_gust
      if gust == "N/A" then 
        maxgust = gust
      elsif maxgust.class == Float && gust.class == Float then       
        if gust > maxgust then 
          maxgust = gust 
        end
      end
      sleep(3+Random.rand(4))
      dt = dt + 1
    end
    if DEBUG>0 then puts "Maximum #{d0} event gust is #{maxgust}" end
    mxg_file.puts(maxgust)
  end
end

#for rw in (2..166) do

#  stdts[0] = excel_data_file.cell(rw,'B',"FireWeatherOutages")
#  stdts[1] = stdts[0] + 1
#  stname = excel_data_file.cell(rw,'I',"FireWeatherOutages")
#  maxgust = 0.0
#  stdts.each do |sd|
#    mesodat = MesoMax.new(sd,stname)
#    gust = mesodat.max_gust
#    if gust > maxgust then maxgust = gust end
#  end 
#  if DEBUG>0 then puts "Maximum 48 hour gust is #{maxgust}" end
#  mxg_file.puts(maxgust)
#  sleep(3+Random.rand(4))
#  
#end

mxg_file.close

