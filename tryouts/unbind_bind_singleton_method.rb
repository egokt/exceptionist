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


class A
  @@ab = 'Hello'

  def self.a
    puts @@ab
  end

  aa = self.method( :a )
  aa = aa.unbind
  self.define_singleton_method( :b, aa )

  def self.a
    puts "a is called"
    self.b
  end
  
end

A.a
