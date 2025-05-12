#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'enum' # immediately when loading this file

  puts "Enumberable objects could be classified by customize criterions:"
  pp (1..10).classify{|x|x%3}

  puts "Enumberable objects could be added head or tail:"
  pp [ 1 , [2],  3 ].unfold_head( :a, :b, :c )
  pp [[1],  2 , [3]].unfold_tail(*[:x, :y, :z])
=end

module Enumerable
  def classify (&block)
    hash = {}
    self.each do|x|
      result = block.call(x)
      (hash[result] ||= []) << x
    end
    return hash
  end

  def add_head *one
    new_array = []
    self.each do|item|
      new_array << ( item.instance_of?(Array) ? one+item : one+[item] )
    end
    return new_array
  end

  def add_tail *one
    new_array = []
    self.each do|item|
      new_array << ( item.instance_of?(Array) ? item+one : [item]+one )
    end
    return new_array
  end

  alias :unfold_head :add_head
  alias :unfold_tail :add_tail
end
