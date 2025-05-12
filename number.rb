#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'number' # immediately when loading this file

  puts "Float to percentage:"
  p 0.5.to_percentage, 0.55.to_percentage, 0.555.to_percentage, 0.5555.to_percentage

  puts '',"Float to binary and hexadecimal:"
  p 1102274184.317453.binform, 1102274184.317453.hexform

  puts '',"Binary and Hexadecimal String to float:"
  p "41b35e88.514498".as_hexnum, "1000001101100110101111010001000.010100010100010010011".as_binnum

  puts '',"The Integral:"
  include Math
  def 积分函数(x,y);x-y;end
  def f(x);x;end
  p a = ∫(5,30,1000.0){|x|积分函数(x, 5)}
  p b = 积分(5,30){|x|f(x)}
=end

class Float
  def to_percentage tail=2
    "#{(self*100).round(tail)}%"
  end
  
  def binform d=100
    mant = self%1
    unless mant==0
      list,cnt = [],0
      while cnt<d && mant%1!=0
        result = (mant%1)*2
        list << "%b"%result.to_i
        mant = result%1
        cnt += 1
      end
      return "%b"%(self.to_i)+'.'+list.join
    else
      return "%b"%self
    end
  end

  def hexform d=100
    mant = self%1
    unless mant==0
      list,cnt = [],0
      while cnt<d && mant%1!=0
        result = (mant%1)*16
        list << "%x"%result.to_i
        mant = result%1
        cnt += 1
      end
      return "%x"%(self.to_i)+'.'+list.join
    else
      return "%x"%self
    end
  end
end

class Integer
  def to_percentage tail=2
    "#{(self/100.0).round(tail)}%"
  end
end

class String
  def to_float
    self.include?("%") ? self.split("%")[0].to_f/100 : self.to_f
  end

  def as_hexnum
    int, float = self.split('.')
    int10, float10 = eval("0x"+int), 0
    float.split('').each_with_index{|f,i|float10 += eval("0x"+f)*16**(-1*(i+1))}
    return (int10+float10).to_f
  end
  
  def as_binnum
    int, float = self.split('.')
    int2, float2 = eval("0b"+int), 0
    float.split('').each_with_index{|f,i|float2 += eval("0b"+f)*2**(-1*(i+1))}
    return (int2+float2).to_f
  end
end

module Math
  def ∫(下限,上限,等分数=1000)
    sum, x, dx = 0, 下限, (上限-下限)/(等分数*1.0)
    loop do
      y = yield(x)
      sum += dx * y
      x += dx
      break if x>上限
    end
    return sum
  end

  alias :积分 :∫
end
