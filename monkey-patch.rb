#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'monkey-patch'

  class A1
    def a1; :a1; end
  end

  class A2 < A1
    def a2; :a2; end
  end

  module Mod1
    def mod1; :mod1; end
  end

  module Mod2
    def mod2; :mod2; end
  end

  class A1
    include Mod1
  end

  a = A2.new
  a.extend Mod2

  puts '',"一个实例的独有方法 = 它的基类实例方法 - 它的父类实例方法 = 本级实例方法 + 本实例扩展方法"
  p a.unique_methods == a.compize(A1)

  puts '',"一个实例的独有方法 根据它选择的基类不同而不同"
  p a.compize(Object), a.compize(A1), a.compize(A2)

  puts '',"但不基于模块方法"
  p a.compize(Mod1), a.compize(Mod2)

  puts '',"打标签备份方法"
  p a.compize(Object), a.mod1, a.mod2
  class << a
    verize :mod1, "20110101"
    revise :mod1, :mod2
    def mod1; :mod3; end
  end
  p a.compize(Object), a.mod1, a.mod2, a.mod1_20110101
=end

class Object
  attr_accessor :main_version, :versions
  
  def versions
    @versions ||= []
  end

  def versions= newver
    @versions ||= []
    @versions << newver unless @versions.include?(newver)
    @main_version = newver
    return newver
  end

  def revise method1,method2
    alias_method "tempfunc1",method1
    alias_method "tempfunc2",method2
    alias_method method1, "tempfunc2"
    alias_method method2, "tempfunc1"
  end
  
  def compize klass=nil
    return self.methods - self.class.superclass.instance_methods if klass.nil?
    return self.methods - klass.instance_methods
  end
  
  def verize name, tag=nil
    tag = Time.new.strftime("%Y%m%d%H%M%S") unless tag
    new_name, old_name = "#{name}_#{tag}",name
    alias_method new_name, old_name
  end
  
  def verize_all tag=nil
    tag = Time.new.strftime("%Y%m%d%H%M%S") unless tag
    unique_methods.each do|um|
      new_name, old_name = "#{um}_#{tag}", um
      alias_method new_name, old_name
    end
  end
  
  def unique_methods
    self.methods - self.class.superclass.instance_methods
  end

  def defm name, &block
    @____ ||= Hash.new
    @____[name] = block
  end
  
  def callm name, *args
    @____[name].call(*args)
  end
end

module Kernel
  def defp name, &block
    @____ ||= Hash.new
    @____[name] = block
  end
  
  def callp name, *args
    @____[name].call(*args)
  end
end
