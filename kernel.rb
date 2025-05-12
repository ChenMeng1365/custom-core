#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'kernel' # immediately when loading this file

  uses 'number', 'string'
  reloads 'number','string'

  module AModule
    def a_method;'a';end
  end
  module BModule
    def b_method;'b';end
  end
  class AClass
    includes AModule, BModule
  end
  obj1 = AClass.new
  p obj1.respond_to?(:a_method), obj1.respond_to?(:b_method)

  obj2 = Object.new
  p obj2.respond_to?(:a_method), obj2.respond_to?(:b_method)
  obj2.extends AModule, BModule
  p obj2.respond_to?(:a_method), obj2.respond_to?(:b_method)

  class A1
    def a2; A2.new; end
  end
  class A2
    def a3; A3.new; end
  end
  class A3
    def a4; A4.new; end
  end
  class A4
    def a5; false; end
  end
  class String
    def to_bill; return false; end
  end

  puts "a.sends(:b,:c,:d) => #{A1.new.sends(:a2,Proc.new{|i|i.send :a3},:a4)} #=> #<A4 ...>"
  # a.sends(:b,:c,:d) => #<A4:0x0000000006425648> #=> #<A4 ...>

  puts "a.cond_insect(:b,:c,:d) => #{A1.new.cond_insect(:a2,lambda{|s|s.send :a3},:a4 ) ? :true : :false}"
  # a.cond_insect(:b,:c,:d) => true

  puts "a.cond_union(:b,:c,:d) => #{A3.new.cond_union(:a4,Proc.new{|s|s.a5},:to_s,'to_bill' ) ? :true : :false} #=> #<A4 ...> "
  # a.cond_union(:b,:c,:d) => true #=> #<A4 ...> 

  puts "a.mapr(fun1, fun2, fun3) => #{"15a".mapr(lambda{|s|s.to_i+1}, lambda{|s|s.to_s+"b"}, lambda{|s|s[-1]}).last}"
  # a.mapr(fun1, fun2, fun3) => b

  puts "a.check_insect(cond1, cond2, cond3) => #{"15a".check_insect( lambda{|s|s.to_i < 20}, lambda{|s|s.to_i > 10}, lambda{|s|s.size==3} )}"
  # a.check_insect(cond1, cond2, cond3) => true

  puts "a.check_union(cond1, cond2, cond3) => #{"15a".check_union( lambda{|s|s.is_a?(Symbol)}, lambda{|s|s.respond_to?(:to_json)}, lambda{|s|s.instance_of?(Module)} )}"
  # a.check_union(cond1, cond2, cond3) => false
=end

module Kernel
  def requires *script_names
    script_names.each do|script_name|
      use script_name#.encode('GBK')
    end
  end

  def use script_path
    if File.exist?(script_path)
      require_relative script_path
    elsif File.exist?(script_path+'.rb')
      require_relative script_path+'.rb'
    else
      warn "无法找到路径: #{script_path}"
    end
  end

  alias :uses :requires
  
  def reloads *script_paths
    script_paths.each do|script_path|
      reload script_path
    end
  end

  def reload script_path
    if File.exist?(script_path)
      load script_path
    elsif File.exist?(script_path+'.rb')
      load script_path+'.rb'
    else
      warn "无法找到路径: #{script_path}"
    end
  end

  def includes *modules
    modules.each do|mod|
      include mod
    end
  end
end

class Object
  def extends *modules
    modules.each do|mod|
      extend mod
    end
  end

  #######################################################
  # walkthrough function-chain
  #######################################################
  
  # CALL: obj.sends(func1, func2, func3, ...)
  # RETN: obj.func1.func2.func3...
  def sends *funcs
    target = self
    funcs.each do|func|
      if func.is_a?(Symbol) or func.is_a?(String)
        target = target.send(*func)
      elsif func.is_a?(Array)
        target = target.send(*func)
      elsif func.instance_of?(Proc)
        target = func.call(*target)
      end
    end
    return target
  end
  
  # CALL: obj.maps(func1, func2, func3, ...)
  # REPR: ... func3.call( func2.call( func1.call(obj) ) )
  # RETN: [stack1, stack2, stack3, ...]
  def mapr *funcs
    red, target = [], self
    funcs.each do|func|
      if func.is_a?(Symbol) or func.is_a?(String)
        target = target.send(*func)
      elsif func.is_a?(Array)
        target = target.send(*func)
      elsif func.instance_of?(Proc)
        target = func.call(*target)
      end
      red << target
    end
    return red
  end
  
  # CALL: obj.cond_ins(attr1, attr2, attr3, ...)
  # REPR: obj.attr1 && obj.attr1.attr2 && obj.attr1.attr2.attr3... 
  # RETN: obj.attr1...attrn/false (false must be specified literally)
  def cond_insect *funcs
    target = self
    flag = funcs.inject(true) do|flag, func|
      if func.is_a?(Symbol) or func.is_a?(String)
        target = target.send(*func)
      elsif func.is_a?(Array)
        target = target.send(*func)
      elsif func.instance_of?(Proc)
        target = func.call(*target)
      end
      flag && target
    end
  end

  # CALL: obj.cond_union(attr1, attr2, attr3, ...)
  # REPR: obj.attr1 || obj.attr1.attr2 || obj.attr1.attr2.attr3...
  # RETN: obj.attrX (Y>X, when obj.attrY is false/not exist, obj.attrX is the first not false)
  def cond_union *funcs
    target = self
    flag = funcs.inject(false) do|flag, func|
      if func.is_a?(Symbol) or func.is_a?(String)
        target = target.send(*func)
      elsif func.is_a?(Array)
        target = target.send(*func)
      elsif func.instance_of?(Proc)
        target = func.call(*target)
      end
      flag || target
    end
  end
  
  #######################################################
  # map-reverse function-chain
  # 
  # Tips:
  # map := obj.map{|o|func(o)}
  # map-reverse := funcs.map{|func|func(obj)}
  #######################################################

  # CALL: obj.check_insect(cond1, cond2, cond3, ...)
  # REPR: cond1(obj) && cond2(obj) && cond3(obj) ...
  # RETN: blockn(obj)/false (false must be specified)
  def check_insect *funcs
    flag = funcs.inject(true) do|flag, func|
      if func.is_a?(Symbol) or func.is_a?(String)
        flag && self.send(func)
      elsif func.is_a?(Array)
        flag && self.send(*func)
      else
        flag && func.call(*self)
      end
    end
  end
  
  # CALL: obj.check_union(cond1, cond2, cond3, ...)
  # REPR: cond1(obj) || cond2(obj) || cond3(obj) ...
  # RETN: true/false
  def check_union *funcs
    flag = funcs.inject(false) do|flag, func|
      if func.is_a?(Symbol) or func.is_a?(String)
        flag || self.send(func)
      elsif func.is_a?(Array)
        flag || self.send(*func)
      else
        flag || func.call(*self)
      end
    end
  end

end


