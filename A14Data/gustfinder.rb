require_relative 'mesomax'
require 'roo'

DEBUG=2

##################

stdate = "10/22/07 2:06 AM"
stname = "VLCC1"

stdts = Array.new()
stdts[0] = DateTime.strptime(stdate,'%m/%d/%y %H:%M %p')
stdts[1] = stdts[0] + 1

maxgust = 0.0
stdts.each do |sd|
  mesodat = MesoMax.new(sd,stname)
  gust = mesodat.max_gust
  if gust > maxgust then maxgust = gust end
end 
if DEBUG>0 then puts "Maximum 48 hour gust is #{maxgust}" end

excel_data_file = Roo::Excelx.new('MGRA-DR3-66-Mbar.xlsx')

mxg_file = File.new('FWO_max_gusts.dat','w')

for rw in (2..166) do

  stdts[0] = excel_data_file.cell(rw,'B',"FireWeatherOutages")
  stdts[1] = stdts[0] + 1
  stname = excel_data_file.cell(rw,'I',"FireWeatherOutages")
  maxgust = 0.0
  stdts.each do |sd|
    mesodat = MesoMax.new(sd,stname)
    gust = mesodat.max_gust
    if gust > maxgust then maxgust = gust end
  end 
  if DEBUG>0 then puts "Maximum 48 hour gust is #{maxgust}" end
  mxg_file.puts(maxgust)
  sleep(3+Random.rand(4))
  
end

mxg_file.close

