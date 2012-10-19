class InstMethodAlredyDefinedWithExceptionClassDef

  class MyException < Exception
  end


  # A raiser that is already defined by the time we call rescue_exception
  def ad_raiser
  end

  rescue_exception MyException, :in => :already_defined_raiser, :with => :catcher
  rescue_exception MyException, :in => :raiser, :with => :catcher
end
