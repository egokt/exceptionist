
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
