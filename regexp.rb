#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'regexp' # immediately when loading this file

  exp1 = Regexp.string 'a+b'
  p 'a+b+c'.match(exp1).to_s

  exp2 = Regexp.string 'a+\d'
  p 'a+3+c'.match(exp2).to_s
=end

class Regexp
  # 从字符串转正则式(含特殊字符,待补完...) ※ No /\\/ changed
  def self.string string
    string.gsub(/([\/\$\^\*\+\?\.\|\(\)\{\}\[\]\-])/){|match|"\\#{match}"}
  end
end
