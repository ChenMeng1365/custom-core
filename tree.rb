#coding:utf-8

############################################################################################################
# The Class Tree is a recursive hash-generator based on Hash.                                              #
#                                                                                                          #
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'tree'

  # 奇怪的数据结构增加了!!!
  a = Tree.init

  # 逐个赋值
  a[1][2][3] = :'4'
  a['1']['2']['3']=4
  p a
  puts Array.new(32,'-').join

  # 直接挂载
  a.mount '1/2/3/4/5/6', '7'
  p a
  a['1/2/3'] = 4
  p a
  puts Array.new(32,'-').join

  # 不能给根目录赋值
  begin
    a['/'] = :root
  rescue Tree::PathError => exception
    puts "#{exception.class}: #{exception.message}\n  #{exception.backtrace.join("\n  ")}"
  end
  begin
    a.mount '/', :home
  rescue Tree::PathError => exception
    puts "#{exception.class}: #{exception.message}\n  #{exception.backtrace.join("\n  ")}"
  end
  p a.route('/')==a['/']
  puts Array.new(32,'-').join

  # 合并到某分支，连接到路径
  b = Tree.init
  b['a/b/c'] = :d
  a.emerge '1/2/3', b['a']
  p a # a['1/2/b'].parent==a['1/2/3'].parent # a['1/2/3'] is 4 and not respond to parent
  begin
    a.contact '1/2/3', b['a']
  rescue Tree::PathError => exception
    puts "#{exception.class}: #{exception.message}\n  #{exception.backtrace.join("\n  ")}"
  end
  a.contact '1/2', b
  p a
  puts Array.new(32,'-').join

  # 回溯父节点
  t = Tree.init
  p t['a/b/c'] = :d
  p t
  puts Array.new(32,'-').join
  p '1:',t['1'],t['1/'].parent
  puts Array.new(32,'-').join
  p '1/2:',t['/1/2'],t['1/2'].parent
  puts Array.new(32,'-').join
  p '1/2/3:',t['1/2/3/'],t['1/2/3'].parent
  puts Array.new(32,'-').join
  p '1/2/3/4:',t['1/2/3/4'],t['1/2/3/4'].parent
  puts Array.new(32,'-').join
  p 'a:',t['a'],t['a'].parent
  puts Array.new(32,'-').join
  p 'a/b:',t['a/b'],t['a/b'].parent
  puts Array.new(32,'-').join
  require './exception'
  p 'a/b/c:',t['a/b/c'],t['/a/b/c'].try(:parent)
  puts Array.new(32,'-').join
  p 'a/b/c/d:',(begin;t['a/b/c/d'];rescue(Exception);'cant pass path="a/b/c/d" with leaf["a/b/c"]';end)
  puts Array.new(32,'-').join
=end

class Tree < Hash
  VERSION = '0.2.0'

  def self.init
    Tree.new{|tree, path|tree[path] = Tree.new(tree,&tree.default_proc) }
  end

  def self.clear
    self.init
  end

  attr_accessor :parent

  def initialize parent=nil
    @parent=parent
    super()
  end

  def [] key
    unless key.instance_of?(String) && key.include?('/')
      child = super(key)
      child.parent = self if child.respond_to? :parent
      return child
    end
    key.include?('/') ? send(:route,key) : super(key)
  end

  def []= key, value
    unless key.instance_of?(String) && key.include?('/')
      super(key,value)
      child = self[key]
      child.parent = self if child.respond_to? :parent
      return child
    end
    key.include?('/') ? (key=='/' ? (raise PathError, "Class Tree can't use '/' as a key except rootself.") : send(:mount,key,value)) : super(key,value)
  end

  def route path
    unless path.instance_of?(String) && path.include?('/')
      post = self[path]
      post.parent = self if post.respond_to? :parent
      return post
    end
    return self if path=='/'
    hops = path.split('/')
    hops.delete ''
    curr = hops.shift
    if hops.empty?
      self[curr]
    else
      # if a leaf exists, any path walkthrough leaf would not pass;
      # if no leaf exists, any path walkthrough could be pass.
      raise PathError, "The current expected path`#{path}` not exist." unless self[curr].respond_to? :route
      self[curr].send "route", hops.join('/')
    end
  end

  # Caution: #mount will arrive the deepest leaf and change the passthrough
  def mount path, store
    unless path.instance_of?(String) && path.include?('/')
      self[path]=store
      post = self[path]
      post.parent = self if post.respond_to? :parent
      return post
    end
    raise PathError, "Class Tree can't mount an value on the root." if path=='/'
    hops = path.split('/')
    hops.delete ''
    curr = hops.shift
    if hops.empty?
      self[curr]=store
      self.delete nil # except ['/']=store to {nil=>store}
    else
      self[curr]=Tree.init
      # self[curr].send "route", hops.join('/')
      self[curr].send "mount", hops.join('/'), store
    end
  end

  # Caution: #emerge can adapt on HashObject but loose the tree-ability
  def emerge path, tree
    if tree.is_a?(Hash)
      hops = path.split("/")
      popz = hops.pop
      curr = hops.join('/')
      target = hops.empty? ? self[popz] : self.route(curr)
      raise PathError, "The current node [\"#{path}\"]=>#{target} not respond to contact/merge." unless target.respond_to? :route
      target.merge!(tree)
      return target
    end
  end

  def contact path, tree
    if tree.is_a?(Tree)
      target = self.route path
      raise PathError, "The current node [\"#{path}\"]=>#{target} not respond to contact/merge." unless target.respond_to? :route
      target.merge!(tree)
      tree.parent = target
    end
  end

  class PathError < Exception
  end
end
