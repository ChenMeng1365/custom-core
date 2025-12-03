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

  puts "Hash could project and serialize on a subscope as a sub hash or array:"
  {a: 1 ,b: 2,c: 3}.project(:a, :c) # => {:a=>1, :c=>3}
  {a: 1 ,b: 2,c: 3}.serialize(:a, :c) # => [1, 3]

  puts "Array could mapping with a subscope as a key-val array:"
  a = [[1,2,3], [4,5,6], [7,8]]
  a.mapping [:a, :b, :c] # => [{:a=>1, :b=>2, :c=>3}, {:a=>4, :b=>5, :c=>6}, {:a=>7, :b=>8, :c=>nil}]
  a.mapping [:a, :d] # => [{:a=>1, :d=>2}, {:a=>4, :d=>5}, {:a=>7, :d=>8}]

  puts "Building a RangeTree to query a range of records:"
  pp(rt = RangeTree.new(records = [
    [[1, 3], :a],
    [[2, 4], :b],
    [[2, 7], :c],
    [[6],    :d],
    [[4, 5], :e],
    [[8],    :f],
    [[10],   :g],
    :y,
    :z
  ]))
  # {1=>{3=>[:a]},
  #  2=>{4=>[:b], 7=>[:c]},
  #  6=>{6=>[:d]},
  #  4=>{5=>[:e]},
  #  8=>{8=>[:f]},
  #  10=>{10=>[:g]},
  #  0=>{0=>[:y, :z]}}

  pp rt.query( Range.new(1,2) )
  # ["complete", {[1, 3]=>[:a]}]

  pp rt.query( [4,7] )
  # ["complete", {[2, 7]=>[:c]}]

  pp rt.query( 6 )
  # ["complete", {[2, 7]=>[:c], [6, 6]=>[:d]}]

  pp rt.query( [1,6] )
  # ["partial",
  #  {[1, 3]=>[:a], [2, 4]=>[:b], [2, 7]=>[:c], [6, 6]=>[:d], [4, 5]=>[:e]}]

  pp rt.query( :a )
  # ["unformal", {[0, 0]=>[]}]
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

class RangeTree < Hash
  attr_reader :a

  # Records := [ [Range|Point, Record] | Record, ... ]
  def initialize records
      merge records
  end

  def merge records
      records.each do|record|
          head, rest = record
          if head.is_a?(Range)
              starter, finisher = head.min, head.max
          elsif head.is_a?(Array)
              starter, finisher = head.sort.first, head.sort.last
          elsif head.is_a?(Numeric)
              starter, finisher = head, head
          else
              starter, finisher, rest = 0, 0, record
          end
          self[starter] ||= {}
          self[starter][finisher] ||= []
          self[starter][finisher] << rest
          self[starter][finisher].uniq!
      end
      @start_keys = self.keys.sort
  end

  def update_key
      @start_keys = self.keys.sort
  end

  def unikey target
      if target.is_a?(Range)
          skey, fkey = target.min, target.max
      elsif target.is_a?(Array)
          skey, fkey = target.sort.first, target.sort.last
      elsif target.is_a?(Numeric)
          skey, fkey = target, target
      else
          skey, fkey = 0, 0
      end
      return skey, fkey
  end

  def locate target
      skey, fkey = unikey(target)
      keys = []
      start_keys = self.keys.sort
      candi_keys = start_keys.select{|sk|sk<=skey}
      candi_keys.each do|candi_key|
          finish_keys = self[candi_key].keys.sort
          cand_keys = finish_keys.select{|fk|fk>=fkey}.map{|cand_key|[candi_key, cand_key]}
          keys += cand_keys
      end
      return keys
  end

  def search target
      keys = []
      skey, fkey = unikey(target)
      self.each do|sk, candis|
          candis.each do|fk, cands|
              next if fkey < sk || fk < skey
              keys << [sk,fk]
          end
      end
      return keys
  end

  def index target
      keys = locate(target)
      if keys.empty?
          return 'partial', search(target)
      elsif keys==[[0,0]]
          return 'unformal', [[0,0]]
      else
          return 'complete', keys
      end
  end

  def query target
      result = {}
      state, keys = index(target)
      keys.each do|keyp|
          sk, fk = keyp
          result[keyp] = self[sk][fk]
      end
      if state=='unformal'
          self[0] ||= {}
          result[[0,0]] = (self[0][0]||[]).include?(target) ? target : []
      end
      return state, result
  end
end
