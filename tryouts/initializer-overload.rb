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
