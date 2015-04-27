class MyClass
#  def initialize (&function)
 def initialize(function) 
 @my_function = function
  end
  def execute(w)
    y = @my_function.call(w)
#    y = @my_function
  end
end

def the_function(a)
  b = a*a
end

c = MyClass.new(method(:the_function))
#the_function = 3
#c = MyClass.new(the_function)
z = c.execute(3)
puts "The value is #{z}"

