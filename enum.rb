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

class Hash
  def project *keys
    new_proj = {}
    keys.each do|key| new_proj[key] = self[key] end
    return new_proj
  end

  def serialize *keys
    return keys.map{|key|self[key]}
  end
end

class Array
  def mapping keys=[]
    head = keys.empty? ? self[0] : keys
    return nil unless head.instance_of?(Array)
    new_records = []
    self.each do|items|
      return nil unless items.instance_of?(Array)
      new_map = {}
      next if items == keys
      head.each_with_index do|field,index|
        new_map[field] = items[index]
      end
      new_records << new_map
    end
    return new_records
  end
end
