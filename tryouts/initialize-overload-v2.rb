# Copyright 2012 Erek Gokturk
#
# This file is a part of Exceptionist.
#
# Exceptionist is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Exceptionist is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Exceptionist.  If not, see <http://www.gnu.org/licenses/>.

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
    @exc_overloaded_methods = {}
    mod_def = "module AExcOverload\n"
    self.class.instance_methods.each do |meth|
      @exc_overloaded_methods[meth] = self.method( meth )
      mod_def += <<-CODE
        define_method '#{meth}'.to_sym do |*args|
          puts "#{meth} was called, and trapped :)"
          @exc_overloaded_methods['#{meth}'.to_sym].call( *args )
        end
      CODE
    end
    mod_def += 'end'
    mod = eval(mod_def)
    self.extend( mod )
  end
end

ai = A.new
ai.a

puts A.instance_methods.inspect
