#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'exception' # immediately when loading this file

  begin
    raise "When trigger an error."
  rescue => exp
    puts exp.info
  end

  obj = Object.new
  obj.extend Insight

  puts "\nWhen calling unknown methods:"
  obj.some_method()
  obj.another_method("hello", 1, "world")
  puts obj.unknown_callings.inspect

  @person = Object.new
  class << @person
    def first_name() 'A' end
    def last_name()  'Z' end
  end

  puts "\nWhen calling an unknown method, it will return nil:"
  p @person.try(:name)
  
  puts "\nWhen calling a definite process, it will try to run:"
  p @person.try{|p|"#{p.first_name} #{p.last_name}"}

  puts "\nWhen calling a defect process, it will respond to rescue:"
  taste proc: proc{1/0}, rescue: proc{p 'Here is final presentation.'}
=end

class Exception
  def self.text instance
    return "SystemError:"+
    "#{instance.backtrace[0]}: #{instance.message}(#{instance.class})"+
    "#{"\n\tfrom "<<instance.backtrace[1..-1].map{|i|i.encode("UTF-8")}.join("\n")}" if instance.is_a?(Exception)
  end

  def info
    return self.class.text(self)
  end
end

module Insight
  def unknown_callings
    @unknown_callings ||= []
  end
  
  def method_missing name,*args
    @unknown_callings ||= []
    @unknown_callings << "#{name}(#{args.join(",")})"
    warn "Unknown calling: #{@unknown_callings[-1]}"
  end
end

class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end
end

class NilClass
  def try(*args)
    nil
  end
end

def taste transacation={} # proc: λ{}, rescue: λ{}, params: *arguments
  process = transacation[:proc]
  recover = transacation[:rescue] || lambda{}
  params  = transacation[:params] || []
  begin
    process.call
  rescue Exception => exp
    puts Exception.text(exp)
    recover.call(*params)
  end
end
