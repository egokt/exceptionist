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


# The plan:
# Override two methods:
#   BasicObject::singleton_method_added for tracking class method definitions
#     -> Note that it's Kernel::singleton_method_added in 1.8.7 (and 1.8.6?)
#     But it doesn't matter. It is overriden in the same way. See below.
#     To override a class method, we unbind it and then add new methods.
#   Module::method_added for tracking instance method definitions

# Usage:
# 
# Note that the type of the method to catch exceptions raised in, and the
# handler method should match: a handler that is an instance method should
# be used to handle exceptions raised in an instance method, whereas only
# a handler that is a class (singleton) method can be used to handle
# exceptions raised in a class (singleton) method.
#
# class A
#   # Two alternative definitions of a handler for a given exception.
#   # my_method is an instance method, and :instance_method is a keyword.
#   rescue_exception MyException, :in => :my_method, :with => :handler_method
#   rescue_exception MyException, :in => [:instance_method, :my_method], 
#     :with => :handler_method
#
#   # definition of a specific handler for a given exception.
#   # my_method is a singleton method
#   rescue_exception MyException, :in => :my_method, :with => :handler_method
#   rescue_exception MyException, :in => [:singleton_method, :my_method], 
#     :with => :handler_method
#
#   # definition of a catch-all exception handler for a given method
#   rescue_exceptions :in => my_method, :with => :another_handler_method
#
#   # definition of a catch-all exception handler for all instance methods
#   rescue_exceptions :with => :handler_for_all_methods
# end

module Exceptionist
  def self.included( base )
    base.extend( ExceptionistDetails::ClassMethods )
    base.class_variable_set( ExceptionistDetails::DATA_VAR_SYM, 
        ExceptionistDetails::DATA_INITIAL_VALUE )
    base.send( :include, ExceptionistDetails::InstanceMethods )
  end
end

# The implementation of the exceptionist.
# The implementation details are in a separate model, in order to prevent
# tainting the included class's namespace with constants "ClassMethods" and
# "InstanceMethods". These two constants appear among the included class's
# constants in this usual form (so we avoid it):
#
# module Exceptionist
#   def self.included?( base )
#     base.extend( ClassMethods )
#     base.send( :include, InstanceMethods )
#   end
#
#   module ClassMethods
#     # class method definitions
#   end
#
#   module InstanceMethods
#     # instance method definitions
#   end
# end
#
# We also store any code that is shared btw the added class and instance 
# methods in this module, so they don't appear in the class that include
# Exceptionist.
module ExceptionistDetails
  SINGLETON_METHOD_SYM = :singleton_method
  INSTANCE_METHOD_SYM = :instance_method

  METHOD_NAME_TEMPL = '__exceptionist_%s_orig'

  DATA_VAR_SYM = '@@__exceptionist_data'.to_sym
  DATA_IN_METHOD_KEY = :in_method_def
  DATA_INITIAL_VALUE = {
    SINGLETON_METHOD_SYM => {},
    INSTANCE_METHOD_SYM => {},
    DATA_IN_METHOD_KEY => false
  }

  ERR_ARG_NOT_EXCEPTION = 'First argument must be kind_of?(Exception)'
  ERR_ARG_MISSING = 
    'Missing mandatory options. Please check documentation of Exceptionist.'

  OPT_KEY_METHOD = :in
  OPT_KEY_HANDLER = :with
  OPT_CHECKERS = {
    OPT_KEY_METHOD => :check_method_reference,
    OPT_KEY_HANDLER => :check_handler_reference }


  def self.ensure_opts( opts, *keys )
    unless 0 == (opts.keys.sort <=> keys.sort)
      raise( ArgumentError, ERR_ARG_MISSING )
    end

    keys.each { |key| check_opt( opts, key ) }
  end


  def self.ensure_exception_class( klass )
    # here is a problem: the following returns false in 1.9.3!
    # class A
    #   class B < Exception
    #   end
    # end
    # A::B.kind_of?( Exception )
    #
    # So this does not work:
    # unless klass.kind_of?( Exception )
    #   raise( ArgumentError, ERR_ARG_NOT_EXCEPTION )
    # end
    #
    # therefore, we check all ancestors to find out if any of them
    # satisfies kind_of?( Exception )
    ancestry = []
    begin
      ancestry << klass
      klass = klass.superclass
    end while klass

    is_exception = !ancestry.detect {|kls| kls == Exception}.nil?
    unless is_exception
      raise( ArgumentError, ERR_ARG_NOT_EXCEPTION )
    end
  end


  def self.check_opt( opts, key )
    checker_method_sym = OPT_CHECKERS[key]
    self.send( checker_method_sym, opts[key] ) if checker_method_sym
  end

  def self.check_method_reference( method_ref )
    method_types = [SINGLETON_METHOD_SYM, INSTANCE_METHOD_SYM]
    method_ref_ok = 
      method_ref.kind_of?( Symbol ) ||
        ( method_ref.kind_of?( Array ) &&
          method_ref.length == 2 &&
          method_types.include?( method_ref.first ) &&
          method_ref.last.kind_of?( Symbol ) )
    raise( ArgumentError, ERR_ARG_METHOD_REF ) unless method_ref_ok
  end


  def self.check_handler_reference( handler_sym )
    handler_sym.kind_of?( Symbol )
  end


  def self.data_for( klass )
    klass.class_variable_get( DATA_VAR_SYM )
  end


  def self.interpret_method_ref( method_ref )
    if method_ref.kind_of?( Symbol )
     [INSTANCE_METHOD_SYM, method_ref]
    else
      method_ref
    end
  end

  # Register instance method exception handler.
  def self.register_ime_handler( klass, except_klass, method_sym, handler_sym )
    inst_methods = klass.instance_methods + klass.private_instance_methods
    if inst_methods.include?( method_sym )
      # method already defined, create a wrapper
      create_im_wrapper( klass, except_klass, method_sym, handler_sym )
    else
      # else postpone to be handled by "method_added"
      inst_methods_data = data_for( klass )[INSTANCE_METHOD_SYM]
      inst_methods_data[method_sym] = [except_klass, handler_sym]
    end
  end

  # Register singleton method exception handler.
  def self.register_sme_handler( klass, except_klass, method_sym, handler_sym )
    singleton_methods = klass.singleton_methods   # TODO: is this enough?
    if singleton_methods.include?( method_sym )
      # method already defined, create a wrapper
      create_sm_wrapper( klass, except_klass, method_sym, handler_sym )
    else
      # else postpone to be handled by "singleton_method_added"
      singleton_data = data_for( klass )[SINGLETON_METHOD_SYM]
      singleton_data[method_sym] = [except_klass, handler_sym]
    end
  end


  def self.create_im_wrapper( klass, except_klass, method_sym, handler_sym )
    overrd_method_name = METHOD_NAME_TEMPL % method_name
    # TODO: remove the puts expressions below
    klass.class_eval %Q{
      alias_method '#{overrd_method_name}'.to_sym, '#{method_name}'.to_sym
      def #{method_name}( *args, &block )
        puts "#{method_name} called"
        puts "#{except_klass.name} will be rescued"
        begin
          #{overrd_method_name}( *args, &block )
        rescue #{except_klass.name} => e
          puts "rescued exception"
          send( '#{handler_sym}'.to_sym, e )
        end
      end
    }
 end


  def self.create_sm_wrapper( klass, except_klass, method_sym, handler_sym )
    overrd_method_name = METHOD_NAME_TEMPL % method_name
    # TODO: remove the puts expressions below
    klass.class_eval %Q{
      define_singleton_method( 
         '#{overrd_method_name % method_name}'.to_sym,
         self.method( '#{method_name}'.to_sym ).unbind )
      def self.#{method_name}( *args, &block )
        puts "self.#{method_name} is called"
        begin
          #{overrd_method_name}( *args, &block )
        rescue #{except_klass.name} => e
          puts "rescued exception"
          send( '#{handler_sym}'.to_sym, e )
        end
      end
    }
  end


  def rescue_all_exceptions_for_method( opts = {} )
    ExceptionistDetails.ensure_opts( opts, OPT_KEY_HANDLER, OPT_KEY_METHOD )

    method_ref = opts[OPT_KEY_METHOD]
    handler_sym = opts[OPT_KEY_HANDLER]

    method_kind, method_sym = interpret_method_ref( method_ref )

    if method_kind == INSTANCE_METHOD_SYM
      ime_handler_params = [self, Exception, method_sym, handler_sym]
      ExceptionistDetails.register_ime_handler( *ime_handler_params )
    else
      sme_handler_params = [self, Exception, method_ref.last, handler_sym]
      ExceptionistDetails.register_sme_handler( *sme_handler_params )
    end
  end


  def rescue_all_exceptions( opts = {} )
    ExceptionistDetails.ensure_opts( opts, OPT_KEY_HANDLER )

    # TODO: Write this. The trick is that every current and future method
    # should be wrapped.
    raise "NOT POSSIBLE, YET. Contact gem author if you are interested."
  end

  module ClassMethods

    # Register an exception handler to handle given exceptions raised 
    # in the given method.
    def rescue_exception( exception, opts = {} )
      ExceptionistDetails.ensure_exception_class( exception )
      ExceptionistDetails.ensure_opts( opts, OPT_KEY_METHOD, OPT_KEY_HANDLER )

      method_ref = opts[OPT_KEY_METHOD]
      handler_sym = opts[OPT_KEY_HANDLER]

      method_kind, method_sym = interpret_method_ref( method_ref )

      if method_kind == INSTANCE_METHOD_SYM
        ime_handler_params = [self, exception, method_sym, handler_sym]
        register_ime_handler( *ime_handler_params )
      else
        sme_handler_params = [self, exception, method_ref.last, handler_sym]
        register_sme_handler( *sme_handler_params )
      end
    end


    def rescue_exceptions( opts = {} )
      if opts.has_key?( OPT_KEY_METHOD )
        rescue_all_exceptions_for_method( opts )
      else
        rescue_all_exceptions( opts )
      end
    end


    def method_added( method_sym )
      exceptionist_data = ExceptionistDetails.data_for( self.class )

      # check if exceptionist is supposed to catch exceptions for this method
      inst_method_data = exceptionist_data[INSTANCE_METHOD_SYM][method_sym]
      if inst_method_data

        # check that we are not already in method_added
        # i.e. method added is already in the call stack
        # and check that we aren't adding the method_added method
        in_method_added_call = exceptionist_data[DATA_IN_METHOD_KEY]
        should_skip = in_method_added_call || method_sym == :method_added
        unless should_skip
          exceptionist_data[DATA_IN_METHOD_KEY] = true

          exception_klass, handler_sym = inst_method_data
          register_ime_handler( self, exception_klass, method_sym, handler_sym )

          exceptionist_data[DATA_IN_METHOD_KEY] = false
        end
      end
    end

    def singleton_method_added( method_sym )
      exceptionist_data = ExceptionistDetails.data_for( self.class )

      # check if exceptionist is supposed to catch exceptions for this method
      singl_method_data = exceptionist_data[SINGLETON_METHOD_SYM][method_sym]
      if singl_method_data

        # check that we are not already in singleton_method_added
        # i.e. singleton_method_added is already in the call stack
        # and check that we aren't adding the singleton_method_added method
        in_singl_method_added_call = exceptionist_data[DATA_IN_METHOD_KEY]
        should_skip = 
          in_singl_method_added_call || method_sym == :singleton_method_added
        unless should_skip
          exceptionist_data[DATA_IN_METHOD_KEY] = true

          exception_klass, handler_sym = singl_method_data
          register_sme_handler( self, exception_klass, method_sym, handler_sym )

          exceptionist_data[DATA_IN_METHOD_KEY] = false
        end
      end
    end
  end

  module InstanceMethods
    # There are no instance methods for the moment.
  end
end

BasicObject.send( :include, Exceptionist )
