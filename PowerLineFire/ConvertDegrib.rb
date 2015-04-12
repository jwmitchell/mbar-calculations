# Program will do a mass conversion of degrib files using command line tool
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 1.0
# Sept 2, 2007
#######

require 'getoptlong'
require 'GeneralOptions'

DEGRIB = "c:\\Program Files\\ndfd\\degrib18\\bin\\degrib.exe" 

# Decode command line arguments
# input_dir = ".\\"
# output_dir = ""
# opt_verbose = false

defopts = [["output_dir","o","REQ","","output_dir: Directory to put shapefiles into"],
                ["input_dir","i","OPT",".\\","input_dir: Directory to read degrib files from"],
                ["fnl","F","NA",false,"fnl:   Read pressure data from FNL file (default False)"]
                ]
go = GeneralOptions.new(defopts)

opt_in = go.options["input_dir"]["value"]
opt_v  = go.options["verbose"]["value"]
opt_out = go.options["output_dir"]["value"]
tableno = go.options["fnl"]["value"] ? 244 : 1


myhelp = "This program runs the degrib.exe program, and uses it to batch create\n ESRI shapefiles.\n"
go.set_help(myhelp)
go.check_help

Dir.foreach(opt_in) {|x|
    xin = opt_in+'\\'+x
    if !File.file?(xin) then next end
    if opt_v then puts xin end
    dgbbuf = `#{DEGRIB} #{xin}  -I`
    if /^#{tableno}\.0.+,\s(\w+)\=.+,\s(\d+)\/(\d+)\/(\d+)\s(\d+):(\d+),\s(\d+\.00)\n/=~dgbbuf then
      wtype = $1
      month = $2  
      day = $3
      year = $4
      hour = $5
      min = $6
      off = $7
      outstring = wtype + "_" + year.to_s + month.to_s + day.to_s + hour.to_s + min.to_s + "_r" + off
      if opt_v then puts outstring end
      xout = opt_out + '\\' + outstring
      l_dgb = `#{DEGRIB} #{xin} -C -msg #{tableno} -Shp -poly small -out #{xout}`
    end
}
