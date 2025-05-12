#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'attribute'

  # use Attribute module with obj[xxx]
  class Sample
    include Attribute
  end
  s1 = Sample.new

  s1['name'], s1[:age] = "sample", 100
  p s1[:name], s1['age'], s1.attrs

  # use Component module with obj.xxx
  s2 = Object.new
  s2.extend Component

  s2.link 'name' => 'sample', age: 100
  p s2.name, s2.age, s2.coms
=end

module Attribute
  def attrs
    @attrs ||= Hash.new
  end

  def [] name
    @attrs ||= Hash.new
    return @attrs[name.to_sym]
  end
  
  def []= name,value
    @attrs ||= Hash.new
    return @attrs[name.to_sym] = value
  end
end

module Component
  def coms
    @attrs ||= Hash.new
  end
  
  def method_missing name,*args
    @attrs ||= Hash.new
    return @attrs[name.to_sym]
  end
  
  def [] name
    @attrs ||= Hash.new
    @attrs[name.to_sym]
  end
  
  def []= name,entity
    @attrs[name.to_sym] = entity
  end
  
  def link pairs
    @attrs ||= Hash.new
    if pairs.class == Hash
      pairs.each{|k,v| @attrs.merge! k.to_sym=>v }
    else
      @attrs.merge! pairs.class.to_sym=>pairs
    end
  end
end
