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
  EHMD_AFTER = :exception_handler_method_def_before_raise_exception_call
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

  def self.create_test_case_set
    param_permutations = INDEPENDENT_PARAM_SETS.permutation
    param_permutations.map do |ecd, ermd, ehmd, erp, re, refmt, ec|
      class_name = new_cls_name( TEST_CASE_CLS_NAME_PREFIX )
      ex_class_name, ex_class_def = exception_class_def( ec )

      <<-CASE_CODE

#{ex_class_def if ecd == ECD_OUTSIDE_CLS}

class #{class_name}

#{ex_class_def if ecd == ECD_INSIDE_CLS}

# the call to inform exceptionist what we want
#{exceptionist_call( erp, re, refmt, ex_class_name )}

end

      CASE_CODE
    end
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
    [cls_name, cls_def]
  end

  def self.exceptionist_call( rescue_from_what, rescue_what, method_type, 
      method_name, exception_class_name )

    case
    when rescue_from_what == ERP_IN_SPECIFIC_METHOD && 
        rescue_what == RE_SPECIFIC_EXCEPTION
      "rescue_exception #{exception_class_name}, :in => :#{method_name}"
    when rescue_from_what == ERP_IN_SPECIFIC_METHOD && 
        rescue_what == RE_ANY_EXCEPTION
      "rescue_exceptions :in => :#{method_name}"
    when rescue_from_what == ERP_IN_ANY_METHOD_IN_CLS && 
        rescue_what == RE_SPECIFIC_EXCEPTION
      # TODO: Not Possible... Need to enhance the exceptionist


        -------------------------
        Working on this
        -------------------------

    when rescue_from_what == ERP_IN_ANY_METHOD_IN_CLS && 
        rescue_what == RE_ANY_EXCEPTION
    else # unknown option
      raise ArgumentError
    end

    
    exceptionist_method = 
      case rescue_from_what
      when ERP_IN_SPECIFIC_METHOD then 'rescue_exception'
      when ERP_IN_ANY_METHOD_IN_CLS then 'rescue_exceptions'

    exception =
      case rescue_what
      when RE_SPECIFIC_EXCEPTION
        gt
      when RE_ANY_EXCEPTION
      else # unknown option
        raise ArgumentError
      end
  end

  def self.new_cls_name( prefix )
    # use sec since epoch + nanosecs to create a unique class name
    do
      cls_name = prefix  + Time.now.strftime( '%s%N' )
    while const_defined?( cls_name.to_sym )
    cls_name
  end
end
