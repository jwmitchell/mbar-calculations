# GeneralOptions.rb
###########
# This will encapsulate all options into a hash, so that it is possible to add options and help through a 
#  one-step process
#########
# J. Mitchell
# M-bar Technologies and Consulting
#########
# Version 0.1
# Sept 2, 2007
#######
# Usage
#
# A list of options may be added to the allowed arguments by supplying an array of four parameter argument descriptors at creation time.
# Format of the array is [long name, short(letter) name, argument option, default, help text]. All are text values except the default.
# Legal values for argment option are "NA" - no argument, "OPT" - optional argument, and "REQ" - required argument
#

require 'getoptlong'

class GeneralOptions
  REQ = GetoptLong::REQUIRED_ARGUMENT
  OPT = GetoptLong::OPTIONAL_ARGUMENT
  NA  = GetoptLong::NO_ARGUMENT
  attr_reader :options
  
  private
  def glopt(astr)
    case astr
      when "NA"
        g = GetoptLong::NO_ARGUMENT
      when "OPT"
        g = GetoptLong::OPTIONAL_ARGUMENT
      when "REQ"
        g = GetoptLong::REQUIRED_ARGUMENT
      else
        puts "ERROR: GOpts:glopt - Unrecognize arg type #{astr}"
        raise
      end
  end 

 public
  def initialize(user_option_list)
    option_list = Array.new
    option_list = user_option_list
    default_opt = Array.new
    default_opt[0] = ["verbose","v","NA",false,"verbose: print extra ouptut"]
    default_opt[1] = ["test", "t","NA",false,"test: will not execute system commands"]
    default_opt[2] = ["help", "h","NA",false,"help: will print all of these comments"]
    @options = Hash.new  
    golo_list = Array.new
    option_list.concat(default_opt)
    option_list.each {|op| 
      option_hash = Hash["long"=>op[0], "short"=>op[1],"arg"=>glopt(op[2]),"default"=>op[3],"help"=>op[4],"value"=>op[3]]
      @options[option_hash["long"]] = option_hash
      golo = ["--"+op[0],"-"+op[1],glopt(op[2])]
      golo_list.push(golo)
    }
    gvlist = golo_list.values_at(0..golo_list.length-1)
    @opts = GetoptLong.new(*gvlist)
    @opts.each do |opt,arg| 
      sopt = opt.slice(2,opt.length-1)
      topt = @options[sopt]
      if !topt then
        puts "***ERROR GeneralOptions -- Illegal option #{opt}"
        raise
      end
      if @options[sopt]["arg"]==NA then
        @options[sopt]["value"] = true
      elsif (@options[sopt]["arg"]==REQ && !arg) then
        puts "***ERROR GeneralOptions -- Required argument missing for #{sopt}"
        raise
      else
        if arg!="" then
          @options[sopt]["value"] = arg
        else
          @options[sopt]["value"] = @options[sopt]["default"] 
        end
      end
    end
  end
  
  def set_help(help_text)
    @helptext = help_text
  end
  
  def check_help
    if @options["help"]["value"] then 
      alltext = @helptext 
        @options.keys.each { |ht|
          alltext = alltext + "\n        " + @options[ht]["help"] 
        }
      puts alltext
      exit
    end
  end
end

