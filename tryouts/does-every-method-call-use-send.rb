set_trace_func proc { |event, file, line, id, binding, classname|
  printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
}

class A
  def a
    puts "a was called"
  end
  alias_method :send_orig, :send
  def send(*args)
    puts "send #{args.inspect}"
  end

  alias_method :ssend_orig, :__send__
  def __send__(*args)
    puts "__send__ #{args.inspect}"
  end
end

ai = A.new
ai.a
