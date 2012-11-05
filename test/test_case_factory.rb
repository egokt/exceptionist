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


class TestCaseFactory

  # - Exception class defined
  # -- In the class that includes exceptionist
  # -- Outside the class that includes exceptionist
  ECD_INSIDE_CLS = :exception_cls_defined_inside_exception_raising_cls
  ECD_OUTSIDE_CLS = :exception_cls_defined_outside_exception_raising_cls
  EXCEPTION_CLS_DEF_LOC_ALT = [ECD_INSIDE_CLS, ECD_OUTSIDE_CLS]

  # - Exception raising method defined 
  # -- before rescue_exception(s) call
  # -- after rescue_exception(s) call
  ERMD_BEFORE = :exception_raising_meth_def_before_raise_exception_call
  ERMD_AFTER = :exception_raising_meth_def_after_raise_exception_call
  EXCEPTION_RAISING_METH_DEF_LOC_ALT = [ERMD_BEFORE, ERMD_AFTER]

  # - Exception handler method defined
  # -- before rescue_exception(s) call
  # -- after rescue_exception(s) call
  EHMD_BEFORE = :exception_handler_method_def_before_raise_exception_call
  EHMD_AFTER = :exception_handler_method_def_after_raise_exception_call
  EXCEPTION_HANDLER_METH_DEF_LOC_ALT = [EHMD_BEFORE, EHMD_AFTER]


  # - Rescue exceptions raised
  # -- in a specific method
  # -- in any method in the class
  ERP_IN_SPECIFIC_METHOD = :rescue_exceptions_raised_from_a_specific_method
  ERP_IN_ANY_METHOD_IN_CLS = :rescue_exceptions_raised_in_any_method_in_cls
  EXCEPTION_RAISING_POINT_ALT = 
    [ERP_IN_SPECIFIC_METHOD, ERP_IN_ANY_METHOD_IN_CLS]

  # - Rescue
  # -- a given exception
  # -- any exception
  RE_SPECIFIC_EXCEPTION = :rescue_a_specific_exception
  RE_ANY_EXCEPTION = :rescue_any_exception
  RESCUED_EXCEPTION_ALT = [RE_SPECIFIC_EXCEPTION, RE_ANY_EXCEPTION]


  # - The method(s) to rescue exceptions of is(are)
  # -- singleton
  # -- instance
  REFMT_SINGLETON = :rescue_exceptions_raised_from_singleton_method
  REFMT_INSTANCE = :rescue_exceptions_raised_from_instance_method
  RESCUE_EXCEPTIONS_FROM_METHOD_TYPE_ALT = [REFMT_SINGLETON, REFMT_INSTANCE]

  # - Raised exception class
  # -- is a subclass of Exception
  # -- is not a subclass of Exception
  EC_SUBCLASS_OF_EXCEPITON = :exception_raised_is_a_subclass_of_exception
  EC_NOT_SUBCLASS_OF_EXCEPTION = :exception_raised_isnt_a_subclass_of_exception
  EXCEPTION_CLASS_ALT = 
    [EC_SUBCLASS_OF_EXCEPITON, EC_NOT_SUBCLASS_OF_EXCEPTION]

  INDEPENDENT_PARAM_SETS = [
    EXCEPTION_CLS_DEF_LOC_ALT,
    EXCEPTION_RAISING_METH_DEF_LOC_ALT,
    EXCEPTION_HANDLER_METH_DEF_LOC_ALT,
    EXCEPTION_RAISING_POINT_ALT,
    RESCUED_EXCEPTION_ALT,
    RESCUE_EXCEPTIONS_FROM_METHOD_TYPE_ALT,
    EXCEPTION_CLASS_ALT
  ]

  TEST_CASE_CLS_NAME_PREFIX = 'ExceptionistTestCase'
  EXCEPTION_CLS_NAME_PREFIX = 'ExceptionistException'

  def self.create_test_case_set( callback_expr, allow_non_exceptions = false )
    param_sets = INDEPENDENT_PARAM_SETS
    unless allow_non_exceptions
      # the last set is the exception class superclass alternatives
      param_sets = param_sets[0...-1] + [[EC_SUBCLASS_OF_EXCEPITON]]
    end
    param_permutations = param_sets.first.product( *param_sets[1..-1] )
    test_cases = 
      param_permutations.map do |params|
        begin
          create_test_case( callback_expr, *params )
        rescue ArgumentError => e
          # just ignore that test case, but log a friendly message
          puts 'This case will be ignored: ' + params.inspect
          # puts e.backtrace.join("\n")
          nil
        end
      end
    test_cases.compact
  end

  def self.create_test_case(
        handler_callback_expr,
        exception_cls_def_loc,
        exception_raising_meth_def_loc,
        exception_handler_meth_def_loc,
        exception_raising_point,
        rescued_exception,
        rescue_exceptions_from_method_type,
        exception_class
      )
    class_name = new_cls_name( TEST_CASE_CLS_NAME_PREFIX )
    ex_class_name, ex_class_def = exception_class_def( exception_class )
    handler_name, handler_definition = 
      handler_def( rescue_exceptions_from_method_type, handler_callback_expr )

    method_name, method_definition =
      method_def( rescue_exceptions_from_method_type, ex_class_name )

    exceptionist_call_params = [
      exception_raising_point,
      rescued_exception,
      rescue_exceptions_from_method_type,
      method_name,
      handler_name,
      ex_class_name
    ]

    <<-CASE_CODE
#{ex_class_def if exception_cls_def_loc == ECD_OUTSIDE_CLS}
class #{class_name}
#{ex_class_def if exception_cls_def_loc == ECD_INSIDE_CLS}
#{handler_definition if exception_handler_meth_def_loc == EHMD_BEFORE}
#{method_definition if exception_raising_meth_def_loc == ERMD_BEFORE}
# the call to inform exceptionist what we want
#{exceptionist_call( *exceptionist_call_params )}
#{method_definition if exception_raising_meth_def_loc == ERMD_AFTER}
#{handler_definition if exception_handler_meth_def_loc == EHMD_AFTER}
end

#{method_runner( rescue_exceptions_from_method_type, class_name, method_name )}
    CASE_CODE
  end

  def self.method_runner( method_type, class_name, method_name )
    retval = 
    case method_type
      when REFMT_INSTANCE
        <<-METHOD_RUNNER
#{class_name}.new.#{method_name}
        METHOD_RUNNER
      when REFMT_SINGLETON
        <<-METHOD_RUNNER
#{class_name}.#{method_name}
        METHOD_RUNNER
      else
        # Internal error. Should not have happened.
        raise ArgumentError
      end
    retval.strip
  end

  def self.method_def( method_type, exception_cls_name )
    method_name = 'rescue_my_exceptions'
    method_definition =
      case method_type
      when REFMT_INSTANCE
        <<-METHOD_CODE
def #{method_name}
  raise #{exception_cls_name}
end
        METHOD_CODE
      when REFMT_SINGLETON
        <<-METHOD_CODE
def self.#{method_name}
  raise #{exception_cls_name}
end
        METHOD_CODE
      else
        # Internal error. Should not have happened.
        raise ArgumentError
      end
    [method_name, method_definition.strip]
  end

  def self.handler_def( method_type, handler_callback_expr )
    handler_name = 'exception_handler'
    retval = 
      case method_type
      when REFMT_INSTANCE
        <<-HANDLER_CODE
def #{handler_name}( exc )
  #{handler_callback_expr}
end
        HANDLER_CODE
      when REFMT_SINGLETON
        <<-HANDLER_CODE
def self.#{handler_name}( exc )
  #{handler_callback_expr}
end
        HANDLER_CODE
      else
        # Internal error. Should not have happened.
        raise ArgumentError
      end
    [handler_name, retval.strip]
  end

  def self.exception_class_def( exception_cls_type )
    cls_name = new_cls_name( EXCEPTION_CLS_NAME_PREFIX )
    cls_def = 
      case exception_cls_type
      when EC_SUBCLASS_OF_EXCEPITON
        <<-EXC_DEF
class #{cls_name} < Exception
end
        EXC_DEF
      when EC_NOT_SUBCLASS_OF_EXCEPTION
        <<-EXC_DEF
class #{cls_name}
end
        EXC_DEF
      else
        # unknown option
        raise ArgumentError
      end
    [cls_name.strip, cls_def.strip]
  end

  def self.exceptionist_call( rescue_from_what, rescue_what, method_type, 
      method_name, handler_method_name, exception_class_name )

    method =
      case method_type
      when REFMT_SINGLETON
        ":in => [:singleton, :#{method_name}]"
      when REFMT_INSTANCE
        "in => [:instance, :#{method_name}]"
      else
        # unknown type. internal error
        raise ArgumentError
      end

    handler = ":with => :#{handler_method_name}"

    case
    when rescue_from_what == ERP_IN_SPECIFIC_METHOD && 
        rescue_what == RE_SPECIFIC_EXCEPTION
      "rescue_exception #{exception_class_name}, #{method}, #{handler}"
    when rescue_from_what == ERP_IN_SPECIFIC_METHOD && 
        rescue_what == RE_ANY_EXCEPTION
      # TODO: Not Possible... Need to enhance the exceptionist
      # "rescue_exceptions :in => :#{method_name}"
      raise ArgumentError
    when rescue_from_what == ERP_IN_ANY_METHOD_IN_CLS && 
        rescue_what == RE_SPECIFIC_EXCEPTION
      # TODO: Not Possible... Need to enhance the exceptionist
      raise ArgumentError
    when rescue_from_what == ERP_IN_ANY_METHOD_IN_CLS && 
        rescue_what == RE_ANY_EXCEPTION
      "rescue_exceptions "
    else # unknown option
      raise ArgumentError
    end
  end

  def self.new_cls_name( prefix )
    # use sec since epoch + nanosecs to create a unique class name
    begin
      cls_name = prefix  + Time.now.strftime( '%s%N' )
    end while const_defined?( cls_name.to_sym )
    cls_name
  end

end
