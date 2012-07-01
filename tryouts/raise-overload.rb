# This does work

module Kernel
  alias_method :__raise_orig__, :raise
  def raise(*args)
    puts "raised #{args.inspect}"
    __raise_orig__(*args)
  end
end


begin

  raise "zuper"

rescue Exception => e
  puts "rescued"
end
