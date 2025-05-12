#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'chinese' # immediately when loading this file
=end

class Object
  def 等于(对象);(self.equal? 对象);end
  def 等于?(对象);(self.equal? 对象);end
  def 等于？(对象);(self.equal? 对象);end
  def 不等于(对象);!(self.equal? 对象);end
  def 不等于?(对象);!(self.equal? 对象);end
  def 不等于？(对象);!(self.equal? 对象);end
  def 包含(对象);self.include?(对象);end # 如果重写，覆盖本方法
  def 包含?(对象);self.include?(对象);end
  def 包含？(对象);self.include?(对象);end
  def 属于(对象);对象.include?(对象);end # 如果重写，覆盖本方法
  def 属于?(对象);对象.include?(对象);end
  def 属于？(对象);对象.include?(对象);end
end

class Numeric
  def 大于(对象);self>对象;end
  def 大于?(对象);self>对象;end
  def 大于？(对象);self>对象;end
  def 大于等于(对象);self>=对象;end
  def 大于等于?(对象);self>=对象;end
  def 大于等于？(对象);self>=对象;end
  def 小于(对象);self<对象;end
  def 小于?(对象);self<对象;end
  def 小于？(对象);self<对象;end
  def 小于等于(对象);self<=对象;end
  def 小于等于?(对象);self<=对象;end
  def 小于等于？(对象);self<=对象;end
  # 等于/不等于 in Object

  ["时","分","秒"].each do|单位|
    define_method 单位.to_sym do
      return self
    end
  end
end

module Enumerable
  def 包含? 其他;self.include?(其他);end # rewrite object
  def 包含？ 其他;self.include?(其他);end # rewrite object
end

module Kernel
  def 打印 *参数
    send :puts,*参数
  end

  def 内视 *参数
    send :p,*参数
  end
  
  def 内视图 *参数
    # require 'pp' # v2.5.0 build-in, no need require when v3.0.0+
    send :pp,*参数
  end
  
  def 休眠 时间
    sleep 时间
  end
end
