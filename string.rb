#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'string' # immediately when loading this file

  puts "String custom strip:"
  p "  hello\n\t".compact, " -- hello -- ".compact_head(' ','-',' '), " -- hello- -".compact_tail('-',' ','-') 

  str = "\nHello, \nworld!\n"
  puts "\nThe string #{str.inspect} width is #{str.width} and height is #{str.height}"

  puts "\nString custom desensitize:"
  puts "1234567890".desensitize("3456")

  puts "\nString custom encoding:"
  str = "中文"
  puts "UTF-8: #{str.inspect}"
  puts "GBK: #{str.force_gbk.inspect}"
  puts "UTF-8: #{str.force_gbk.force_utf8.inspect}"
=end

class String
  def compact *params
    clone = self.clone
    (params.empty? ? [" ","\t","\n"] : params).each do|param|
      clone.gsub!(/^#{Regexp.escape(param)}+|#{Regexp.escape(param)}+$/, "")
    end
    return clone
  end

  def compact_tail *params
    clone = self.clone
    (params.empty? ? [" ","\t","\n"] : params).each do|param|
      clone.gsub!(/#{Regexp.escape(param)}+$/, "")
    end
    return clone
  end
  
  def compact_head *params
    clone = self.clone
    (params.empty? ? [" ","\t","\n"] : params).each do|param|
      clone.gsub!(/^#{Regexp.escape(param)}+/, "")
    end
    return clone
  end
  
  def effective?
    !self.strip.empty?
  end
  
  def width
    self.split("\n").map(&:size).max || 0
  end
  
  def height
    self.split("\n").reject(&:empty?).size
  end

  def desensitize target,holder='*',full=:full
    self.gsub(target,(full==:full ? Array.new(target.size,holder).join : holder))
  end

  def force_gbk
    String.new(self).encode('GBK').force_encoding('ASCII-8BIT')
  end
  
  def force_utf8 default="GBK"
    String.new(self).force_encoding(default).encode('UTF-8')
  end
end
