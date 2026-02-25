#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: UTF-8

=begin
| 关键特性 | 说明　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　  |
|---------|---------------------------------------------------------------|
| 追踪功能 | TracePoint 是 Ruby 内置的追踪 API，性能比 `set_trace_func` 更好 |
| 层级缩进 | 通过 `call_depth` 显示调用层级，便于阅读                        |
| 对象信息 | 记录类名、object_id、inspect 结果、集合 size 等                   |
| 局部变量 | 在每一行记录当前的局部变量状态                                   |
| 参数追踪 | 方法调用时记录传入的参数                                        |
| 源码显示 | 显示当前执行的源代码行                                          |
| 安全截断 | 超长字符串自动截断，防止日志爆炸                                 |

※注意： `trace_lines: true` 会追踪每一行代码，性能开销较大，适合调试小段代码；只追踪方法调用（默认）性能更好，适合生产环境追踪。

# 使用方法:
require 'cc'
CC.use 'trace'
ExecutionTracer.enable! # log_path: 'execution.log', trace_lines: false, max_depth: 100
hello(:world)
ExecutionTracer.disable!

# 设置环境变量调用：
`EXECUTION_TRACER_AUTO_START=true EXECUTION_TRACER_LOG=my_trace.log EXECUTION_TRACER_TRACE_LINES=true ruby 自定义脚本.rb`
=end

require 'json'
require 'date'

module ExecutionTracer
  class << self
    attr_reader :logger, :enabled, :log_file, :call_depth
    
    def enable!(log_path: 'execution.log', trace_lines: false, max_depth: 100)
      return if @enabled
      
      time = Time.now
      @logger = []
      @logger << {
        'time' => time,
        'event' => "Execution Trace Start",
        'version' => RUBY_VERSION,
        'process-id' => Process.pid,
        'log-path' => log_path
      }

      @log_file = File.open(log_path, 'a')
      @log_file.puts "\n" + "="*80
      @log_file.puts "[#{time}] Execution Trace Start"
      @log_file.puts "Ruby Version: #{RUBY_VERSION}"
      @log_file.puts "Process PID: #{Process.pid}"
      @log_file.puts "="*80 + "\n"
      @log_file.flush
      
      @enabled = true
      @call_depth = 0
      @max_depth = max_depth
      
      setup_tracepoint(trace_lines)
      
      puts "[ExecutionTracer] 已启用，日志写入: #{File.absolute_path(log_path)}"
    end
    
    def disable!
      return unless @enabled
      
      time = Time.now
      @logger ||= []
      @logger << {
        'time' => time,
        'event' => "Execution Trace End",
        'process-id' => Process.pid
      }

      @tracepoint&.disable
      @enabled = false
      
      @log_file.puts "\n" + "="*80
      @log_file.puts "[#{time}] Execution Trace End"
      @log_file.puts "="*80 + "\n"
      @log_file.close
      
      puts "[ExecutionTracer] 已禁用，日志已保存"
    end
    
    def log(message)
      return unless @enabled && @log_file
      @log_file.puts(message.encode("UTF-8"))
      @log_file.flush
    end
    
    private
    
    def setup_tracepoint(trace_lines)
      events = [:call, :return, :c_call, :c_return]
      events << :line if trace_lines
      
      @tracepoint = TracePoint.new(*events) do |tp|
        next if internal_file?(tp.path)
        next if @call_depth > @max_depth
        
        case tp.event
        when :call, :c_call
          @call_depth += 1
          log_method_call(tp)
        when :return, :c_return
          log_method_return(tp)
          @call_depth -= 1
        when :line
          log_line_execution(tp)
        end
      end
      
      @tracepoint.enable
    end
    
    def log_method_call(tp)
      receiver = tp.self
      method_name = tp.method_id
      file = tp.path
      line = tp.lineno
      defined_class = tp.defined_class
      
      # 收集对象信息
      object_info = extract_object_info(receiver)
      
      # 收集参数信息（如果可能）
      args_info = extract_arguments(tp.binding) if tp.binding
      
      indent = "  " * [@call_depth - 1, 0].max
      log_message = format_log_entry(
        event: "CALL",
        indent: indent,
        file: file,
        line: line,
        method: "#{defined_class}##{method_name}",
        object: object_info,
        args: args_info
      )
      
      log(log_message)
    end
    
    def log_method_return(tp)
      receiver = tp.self
      method_name = tp.method_id
      file = tp.path
      line = tp.lineno
      
      object_info = extract_object_info(receiver)
      return_value = safe_inspect(tp.return_value) if tp.respond_to?(:return_value)
      
      indent = "  " * [@call_depth - 1, 0].max
      log_message = format_log_entry(
        event: "RETURN",
        indent: indent,
        file: file,
        line: line,
        method: "#{tp.defined_class}##{method_name}",
        object: object_info,
        return: return_value
      )
      
      log(log_message)
    end
    
    def log_line_execution(tp)
      file = tp.path
      line = tp.lineno
      
      # 获取当前行的代码（如果文件可读）
      source_line = read_source_line(file, line)
      
      # 获取局部变量信息
      local_vars = extract_local_variables(tp.binding) if tp.binding
      
      log_message = format_log_entry(
        event: "LINE",
        indent: "  " * (@call_depth < 0 ? @call_depth*(-1) : @call_depth),
        file: file,
        line: line,
        source: source_line,
        locals: local_vars
      )
      
      log(log_message)
    end
    
    def extract_object_info(obj)
      info = {
        class: obj.class.name,
        object_id: obj.object_id,
        inspect: safe_inspect(obj)
      }
      
      # 如果是集合类型，记录大小
      if obj.respond_to?(:size)
        info[:size] = obj.size rescue "N/A"
      end
      
      # 如果是字符串，记录长度
      if obj.is_a?(String)
        info[:length] = obj.length
        info[:encoding] = obj.encoding.name
      end
      
      # 如果是数字，记录值
      if obj.is_a?(Numeric)
        info[:value] = obj
      end
      
      info
    rescue => e
      { error: "无法提取对象信息: #{e.message}" }
    end
    
    def extract_arguments(binding_context)
      return nil unless binding_context
      
      # 尝试获取方法参数（Ruby 2.7+ 支持）
      if binding_context.respond_to?(:local_variables)
        vars = binding_context.local_variables
        args = {}
        vars.each do |var|
          begin
            args[var] = safe_inspect(binding_context.local_variable_get(var))
          rescue
            args[var] = "<unreadable>"
          end
        end
        args
      end
    rescue => e
      { error: e.message }
    end
    
    def extract_local_variables(binding_context)
      return nil unless binding_context
      
      vars = {}
      binding_context.local_variables.each do |var|
        begin
          value = binding_context.local_variable_get(var)
          vars[var] = {
            class: value.class.name,
            inspect: safe_inspect(value)[0..100] # 限制长度
          }
        rescue => e
          vars[var] = { error: e.message }
        end
      end
      vars
    rescue => e
      { error: e.message }
    end
    
    def format_log_entry(**data)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S.%3N")
      indent = data.delete(:indent) || ""
      event = data.delete(:event)
      
      @logger ||= []
      record = {"time"=>timestamp, "indent"=>indent.strip, "event"=>event}

      # 构建格式化的日志行
      lines = ["[#{timestamp}] #{indent}[#{event}]"]
      
      data.each do |key, value|
        next if value.nil?
        
        formatted_value = case value
        when Hash
          value.map { |k, v| "#{k}=#{truncate(v.to_s, 80)}" }.join(", ")
        when String
          truncate(value, 100)
        else
          truncate(value.to_s, 100)
        end
        
        record[key] = formatted_value
        lines << "  #{key}: #{formatted_value}"
      end
      
      @logger << record
      lines.map{|line|line.encode("UTF-8")}.join("\n")
    end
    
    def read_source_line(file, line_num)
      return nil unless File.exist?(file)
      
      File.readlines(file)[line_num - 1]&.strip
    rescue => e
      "<无法读取: #{e.message}>"
    end
    
    def safe_inspect(obj)
      obj.inspect
    rescue => e
      "<inspect error: #{e.message}>"
    end
    
    def truncate(str, max_len)
      str.length > max_len ? str[0...max_len] + "..." : str
    end
    
    def internal_file?(path)
      return true if path.nil? || path.empty?
      return true if path.start_with?('<internal:')
      return true if path.include?('/ruby/')
      return true if path.include?('execution_tracer.rb') # 忽略追踪器本身
      false
    end
  end
end

# 自动启动（如果设置了环境变量）
if ENV['EXECUTION_TRACER_AUTO_START']
  ExecutionTracer.enable!(
    log_path: ENV['EXECUTION_TRACER_LOG'] || 'execution.log',
    trace_lines: ENV['EXECUTION_TRACER_TRACE_LINES'] == 'true'
  )
end

# 注册退出钩子
at_exit { ExecutionTracer.disable! if ExecutionTracer.enabled }
