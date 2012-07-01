# The plan:
# Override two methods:
#   BasicObject::singleton_method_added for tracking class method definitions
#     -> Note that it's Kernel::singleton_method_added in 1.8.7 (and 1.8.6?)
#     But it doesn't matter. It is overriden in the same way. See below.
#     To override a class method, we unbind it, remove the original, and
#     add new methods.
#   Module::method_added for tracking instance method definitions

set_trace_func proc { |event, file, line, id, binding, classname|
#  printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
}

class A

  @@in_method_added = false

  def self.method_added( method_name )
    unless @@in_method_added
      puts "Method added: #{method_name}"
      unless /\A__exceptionist_/ =~ method_name
        @@in_method_added = true
        class_eval %Q{
          alias_method '__exceptionist_#{method_name}_orig'.to_sym, '#{method_name}'.to_sym
          def #{method_name}( *args, &block )
            puts "#{method_name} called"
            __exceptionist_#{method_name}_orig( *args, &block )
          end
        }
        @@in_method_added = false
      end
    end
  end

  def self.singleton_method_added( method_name )
    unless @@in_method_added || method_name == :singleton_method_added
      puts "singleton method added: #{method_name}"
      unless /\A__exceptionist_/ =~ method_name
        @@in_method_added = true
        class_eval %Q{
          define_singleton_method( 
              '__exceptionist_#{method_name}_orig'.to_sym,
              self.method( '#{method_name}'.to_sym ).unbind )
          def self.#{method_name}( *args, &block )
            puts "self.#{method_name} is called"
            __exceptionist_#{method_name}_orig( *args, &block )
          end
        }
        @@in_method_added = false
      end
    end
  end

  def a
  end

  def self.b
  end
end

A.new.a
A.b
