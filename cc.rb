#coding:utf-8

$modlist = [
  'cc',
  'attribute',
  'chinese',
  'chrono',
  'enum',
  'exception',
  'file',
  'kernel',
  'monkey-patch',
  'number',
  'regexp',
  'string',
  'tree'
]

module CC
  module_function

  def list *names
    $modlist.each do|mod|
      puts mod if names.include?(mod) || names.empty?
    end
  end

  def select *args
    if args.include?(:all)
      $modlist.each do|mod|
        load(mod+'.rb')
      end
    else
      args.each do|arg|
        load(arg+'.rb') if $modlist.include?(arg)
      end
    end
  end

  def use *args
    select(*args)
  end
end
