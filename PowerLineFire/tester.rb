class Tester
  
  def initialize
    @@h1 = Hash.new
  end
  
  def set_hash
    @@h1["first"] = 1
    @@h1["last"] = 2
  end 
  
  def get_h
    @@h1
  end
  
end

test = Tester.new
test.set_hash
print test.get_h["first"]