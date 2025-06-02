#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'file'

  puts "The current directory:"
  pp '..'.directory

  puts '',"The filepaths under current directory:"
  pp '..'.directory.paths
  
  puts '',"The current directory whether include somewhere part of pathname:"
  pp '..'.directory.find?(__FILE__)

  tab1 = File.read("1/1.txt")
  tab2 = File.read("2/1.txt")
  text1 = Diff.shift tab1, 2.row, 1.row
  text1 = Diff.shift text1, 5.line, 1.row
  text1 = Diff.shift text1, 8.line, 2.rows
  text2 = Diff.shift tab2, 7.row, 1.line
  text2 = Diff.shift text2, 11.row, 1.line
  tab = Diff.show text1, text2
  File.write "tab.txt", tab.map{|t|t.join("|")}.join("\n")

  File.diff('1/1.txt', '2/1.txt', 'tmp.diff', 'git diff')
  File.diffs('1', '2', 'tmp.diff', 'git diff').save_into 'diff.txt'
=end

class String
  # "PathString" => {FolderTree}
  def directory_detection
    folder = {}
    Dir["#{self}/*"].each do|path|
      next if ["..","."].include?(path)
      epath = File.expand_path(path)
      pathname = epath.split("/")[-1]
      if File.directory?(epath)
        sub = epath.directory_detection
        folder.merge!(pathname=>sub) # epath
      else
        folder[pathname] = "file" # epath
      end
    end
    return folder
  end

  alias :directory :directory_detection

  def self.load_from path
    buffer = File.open(path,'r'){|f|f.read}
    if buffer.encoding=="GBK"
      begin
        return buffer.encode("UTF-8") 
      rescue Encoding::UndefinedConversionError=>e
        if e.message.include?("from GBK to UTF-8")
          buffer.force_encoding("UTF-8")
        else
          raise "#{e.message} (#{e.class})"
        end
      end
    end
    return buffer
  end
  
  def save_into path
    File.open(path,'w'){|f|f.write(self)}
  end
  
  def save_binary_into path
    File.open(path,'wb'){|f|f.write(self)}
  end

  def append_into path
    unless File.exist?(path)
      save_into(path)
    else
      File.open(path,'a'){|f|f.write(self)}
    end
  end
end

class Hash
  # {FolderTree} => ["PathString"List]
  def paths
    traces = []
    self.each do|name,tag|
      traces << [name]
    end
    self.each do|name,tag|
      if tag.is_a?(Hash)
        subs = tag.paths
        new_traces = []
        traces.each do |trace|
          if trace[-1] == name
            new_sub = []
            subs.each{|vector|new_sub << trace + vector}
            new_traces += new_sub
          else
            new_traces << trace
          end
        end
        traces = new_traces
      end
    end
    return traces
  end
  
  def find_path nodename
    result = []
    self.paths.each do|path|
      result << path.join("/") if path.join("/").include?(nodename)
    end
    return result
  end

  alias :"find?" :find_path
end

# load('json.rb') # require 'json'
# load('yaml.rb') # require 'yaml'

class File
  def self.load_json filepath
    path = filepath.include?('.json') ? filepath : filepath+".json"
    context = File.open(path,'r'){|f|f.read}.force_encoding("UTF-8")
    JSON.parse(context)
  end
  
  # ...
  # yaml = YAML.dump( obj )
  # obj = YAML.load( yaml )
  # File.open( 'path.yaml', 'w' ) do |out| YAML.dump( obj, out ) end
  # obj = YAML.load_file("path.yaml")
  def self.load_yaml filepath
    path = filepath.include?('.yml') ? filepath : filepath+".yml"
    context = File.open(path,'r'){|f|f.read}.force_encoding("UTF-8")
    YAML.load(context)
  end

  # 这个方法保证对象中的unicode被正确转换为YAML内容（已过时）
  # eg. File.open('temp.yml','w'){|f|f.write [ "alphabet",{:symbol=>123.321},'"其♂ 他·文♀字"' ].to_yaml.unicode}
  # def unicode
  #   yaml_string = self#.to_yaml # only valid for yaml string!
  #   yml_unic = begin
  #     str = (/\"(.+)\"/.match yaml_string)[0]
  #     yaml_string.gsub(str,eval(":#{str}").to_s)
  #   rescue
  #     yaml_string
  #   end
  #   return yml_unic
  # end

  def self.clear_edit_backfile path
    if File.exist?(path) && path[-1]=='~'
      File.delete(path)
      puts "Delete #{path} successfully!"
    else
      puts "Cannot delete #{path}, just pass away!"
    end
  end

  def self.clear_edit_backfile_path path='.'
    Dir["#{path}/*~"].each do|path|
      begin
        File.delete(path)
        puts "Delete #{path} successfully!"
      rescue
        puts "Cannot delete #{path}, just pass away!"
      end
    end
  end

  def self.diff left_path, right_path, report_path='tmp.diff', selector='diff'
    `echo "\n#{Array.new(64,'-').join}\n" >> #{report_path}`
    `echo "<< #{left_path} <=> #{right_path} >>\n" >> #{report_path}`
    `#{selector} #{left_path} #{right_path} >> #{report_path}`
  end

  def self.diffs adir, bdir, head='.',selector='diff'
    alist = (head+'/'+adir).directory_detection.paths.map{|path|path.join('/')}
    blist = (head+'/'+bdir).directory_detection.paths.map{|path|path.join('/')}

    onlyalist = alist - blist
    onlyblist = blist - alist
    commnlist = alist & blist

    report = []
    unless onlyalist.empty?
      report << "only #{adir} exist files:\n"
      report += onlyalist.map{|path|path}
      report << '' << Array.new(64,'=').join
    end

    unless onlyblist.empty?
      report << "\nonly #{bdir} exist files:\n"
      report += onlyblist.map{|path|path}
      report << '' << Array.new(64,'=').join
    end

    unless commnlist.empty?
      report << "\ncommon files comparison:"
      commnlist.each do|path|
        self.diff("#{head}/#{adir}/#{path}", "#{head}/#{bdir}/#{path}", 'diff.tmp', selector)
      end
      File.exist?('diff.tmp') and report << File.read('diff.tmp')
      File.exist?('diff.tmp') and File.delete('diff.tmp')
    end

    return report.join("\n")
  end
end

module Diff
  module_function

  # 该方法只用来排成两列显示, 并不真正执行比较, 已经有File.diff/File.diffs完成该工作
  def show text1, text2, shift=0
    list1 = text1.instance_of?(String) ? text1.split("\n") : text1
    list2 = text2.instance_of?(String) ? text2.split("\n") : text2
    max1 = list1.map{|r|r.length}.max
    max2 = list2.map{|r|r.length}.max
    shift > 0 and (list1 = Array.new(shift, "")+list1) #and (list2 += Array.new(shift, ""))
    shift <= 0 and (list2 = Array.new(shift, "")+list2)# and (list1 += Array.new(shift, ""))
    size = [list1.size, list2.size].max+(shift>0 ? shift : shift*(-1))
    rows = []
    size.times.each do|index|
      rows << [
        list1[index].to_s+Array.new(max1 - list1[index].to_s.length, " ").join, 
        list2[index].to_s+Array.new(max2 - list2[index].to_s.length, " ").join
      ]
    end
    return rows
  end
  
  def shift text, index, shift=1
    list = text.instance_of?(String) ? text.split("\n") : text
    shift.times.each do list.insert(index,"") end
    return list.join("\n")
  end
end

class Integer
  # 数字计量单位
  def line;return self;end
  def lines;return self;end
  def row;return self;end
  def rows;return self;end
end
