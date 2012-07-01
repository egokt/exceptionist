set_trace_func proc { |event, file, line, id, binding, classname|
#  printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
}

class A
  def initialize
  end
  def a
    puts "hello, my name is a"
  end
end

class A
  alias_method( :initialize_orig, :initialize )
  def initialize
    puts self.class.instance_methods
    self.class.instance_methods.each do |meth|
      meth_orig = 'orig_' + meth.gsub( /\?/, '_' )
      self.class.class_eval <<-CODE
        alias_method '#{meth_orig}'.to_sym, '#{meth}'.to_sym
        define_method '#{meth}'.to_sym do |*args|
          puts "#{meth} was called, and trapped :)"
          orig_send( '#{meth_orig}'.to_sym, *args )
        end
      CODE
    end
  end
end

ai = A.new
ai.a

puts A.instance_methods.inspect
