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

require 'test_helper'

class ExceptionistTest < Test::Unit::TestCase


  def test_cases_produced_by_test_case_factory
    case_feedback_expr = 'ExceptionistTest.case_feedback_method'
    test_cases = TestCaseFactory.create_test_case_set( case_feedback_expr )

    test_cases.each do |test_case|
      run_test_case( test_case )
    end
  end

  def self.case_feedback_method
   @@case_feedback_received = true
  end

  private

  # here for debugging test cases
  def run_test_case_print_only( test_case )
    puts test_case + "\n\n\n\n\n"
  end

  def run_test_case( test_case )
    @@case_feedback_received = false
    assert_nothing_raised do
      begin
        eval test_case
      rescue Exception => e
        puts "\n\nException: #{e.message}\n\n#{test_case}\n\n" +
          e.backtrace.join( "\n" )
        raise
      end
    end
    assert @@case_feedback_received
  end

end
