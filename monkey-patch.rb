#coding:utf-8

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin # 旧版
  require 'cc'
  CC.use 'monkey-patch'

  class A1
    def a1; :a1; end
  end

  class A2 < A1
    def a2; :a2; end
  end

  module Mod1
    def mod1; :mod1; end
  end

  module Mod2
    def mod2; :mod2; end
  end

  class A1
    include Mod1
  end

  a = A2.new
  a.extend Mod2

  puts '',"一个实例的独有方法 = 它的基类实例方法 - 它的父类实例方法 = 本级实例方法 + 本实例扩展方法"
  p a.unique_methods == a.compize(A1)

  puts '',"一个实例的独有方法 根据它选择的基类不同而不同"
  p a.compize(Object), a.compize(A1), a.compize(A2)

  puts '',"但不基于模块方法"
  p a.compize(Mod1), a.compize(Mod2)

  puts '',"打标签备份方法"
  p a.compize(Object), a.mod1, a.mod2
  class << a
    verize :mod1, "20110101"
    revise :mod1, :mod2
    def mod1; :mod3; end
  end
  p a.compize(Object), a.mod1, a.mod2, a.mod1_20110101
=end

=begin # 新版
  puts "=" * 60
  puts "模块级方法版本控制系统 v4 演示"
  puts "=" * 60

  # ========================================
  # 定义版本化模块
  # ========================================
  module Calculator
    include MonkeyPatch

    # 方式1: 传统 block
    ADD_V1 = defv(:add) { |a, b| a + b }
    puts "[方式1] 定义 add v1, 签名: #{ADD_V1}"

    ADD_V2 = defv(:add) { |a, b| 
      result = a + b
      puts "[v2] 计算 #{a} + #{b} = #{result}"
      result 
    }
    puts "[方式1] 定义 add v2, 签名: #{ADD_V2}"
  end

  # 方式2: 从外部数组批量生成
  EXTERNAL_SPECS = [
    [:greet, "World", proc { |name| "Hello, #{name}!" }],
    [:multiply, 1, proc { |a, b| a * b }],
  ]

  module GreetingService
    include MonkeyPatch

    EXTERNAL_SPECS.each do |spec|
      name, default, body = spec
      sig = defv(name, default, body)
      puts "[方式2] 定义 #{name}, 默认=#{default.inspect}, 签名: #{sig}"
    end
  end

  # ========================================
  # 测试 module_function 效果
  # ========================================
  puts "\n" + "-" * 50
  puts "测试 module_function 效果（v4 核心特性）"
  puts "-" * 50

  # 实例调用
  obj = Object.new.extend(Calculator)
  puts "obj.add(2, 3) = #{obj.add(2, 3)}"

  # 模块方法调用（module_function 效果）
  puts "Calculator.add(10, 20) = #{Calculator.add(10, 20)}"
  puts "Calculator.send(:add, 5, 7) = #{Calculator.send(:add, 5, 7)}"

  # 模块方法也走版本控制
  puts "\n--- 模块方法版本切换 ---"
  puts "当前默认: Calculator.add(1, 1) = #{Calculator.add(1, 1)}"

  Calculator.rollback_to(:add, Calculator::ADD_V1)
  puts "回滚到 v1: Calculator.add(1, 1) = #{Calculator.add(1, 1)}"

  Calculator.rollback_to(:add, Calculator::ADD_V2)
  puts "恢复 v2: Calculator.add(1, 1) = #{Calculator.add(1, 1)}"

  # 实例调用同步受影响（共享版本库）
  puts "obj.add(1, 1) = #{obj.add(1, 1)}  (与模块方法同步)"

  # ========================================
  # 测试 GreetingService
  # ========================================
  puts "\n" + "-" * 50
  puts "测试 GreetingService（方式2 + module_function）"
  puts "-" * 50

  puts "GreetingService.greet = #{GreetingService.greet}"
  puts 'GreetingService.greet("Alice") = ' + GreetingService.greet("Alice").to_s
  puts "GreetingService.multiply(3, 4) = #{GreetingService.multiply(3, 4)}"

  # 实例调用
  g = Object.new.extend(GreetingService)
  puts "g.greet = #{g.greet}"
  puts 'g.greet("Bob") = ' + g.greet("Bob").to_s

  # ========================================
  # 版本历史
  # ========================================
  puts "\n" + "-" * 50
  puts "版本历史"
  puts "-" * 50

  Calculator.version_history(:add).each do |v|
    puts "  Calculator.add: #{v[:signature]} @ #{v[:timestamp]}"
  end

  GreetingService.version_history(:greet).each do |v|
    puts "  GreetingService.greet: #{v[:signature]} @ #{v[:timestamp]}"
  end

  # ========================================
  # 跨模块隔离
  # ========================================
  puts "\n" + "=" * 60
  puts "跨模块隔离测试"
  puts "=" * 60
  puts "Calculator 版本库: #{Calculator.versioned_methods.inspect}"
  puts "GreetingService 版本库: #{GreetingService.versioned_methods.inspect}"

  # ========================================
  # 全局注册表
  # ========================================
  puts "\n" + "=" * 60
  puts "全局注册表结构"
  puts "=" * 60
  MonkeyPatch::VERSION_REGISTRY.each do |mod, methods|
    puts "模块: #{mod}"
    methods.each do |name, versions|
      puts "  方法: #{name}"
      versions.each do |sig, vm|
        next if sig == :__latest__
        puts "    [#{sig}] => #{vm}"
      end
      puts "    [LATEST] => #{versions[:__latest__]}"
    end
  end
=end


# ============================================================
# 新版本MonkeyPatch
# 模块级方法版本控制系统 (Module Method Versioning) - v4
# ============================================================
# 特性：
#   1. 模块作为方法仓库，每个方法名对应一个版本链
#   2. 支持按签名回溯历史版本
#   3. 不传签名时默认调取最新版本
#   4. 模块间版本隔离，互不干扰
#   5. 支持两种调用方式：
#      - 传统 block: defv(:name) { |a| ... }
#      - 数组重构:   defv(:name, default_param, proc)
#   6. module_function 支持：模块方法也走版本控制
#      - obj.a 和 A.a 共享同一个版本库
# ============================================================

module MonkeyPatch
  VERSION_REGISTRY = {}
  SIGNATURE_COUNTER = Hash.new(0)

  class VersionedMethod
    attr_reader :name, :signature, :body, :timestamp, :module_ref

    def initialize(name:, signature:, body:, module_ref:)
      @name = name
      @signature = signature
      @body = body
      @timestamp = Time.now
      @module_ref = module_ref
    end

    def call(*args)
      outer_block = block_given? ? Proc.new : nil
      if outer_block
        @module_ref.instance_exec(*args, outer_block, &@body)
      else
        @module_ref.instance_exec(*args, &@body)
      end
    end

    def to_s
      "#<VersionedMethod #{@module_ref}##{@name}@#{@signature} #{@timestamp}>"
    end
    alias inspect to_s
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # ----------------------------------------------------------
  # 类方法接口
  # ----------------------------------------------------------
  module ClassMethods
    def define_versioned_method(name, *args, signature: nil, &block)
      if block_given?
        _register_version(name, signature: signature, body: block)
      elsif args.size >= 2 && args[1].is_a?(Proc)
        default_param = args[0]
        body_proc = args[1]

        wrapped = proc { |*call_args|
          if call_args.empty?
            body_proc.call(default_param)
          else
            body_proc.call(*call_args)
          end
        }
        _register_version(name, signature: signature, body: wrapped)
      else
        raise ArgumentError, "必须提供方法块，或传入 (name, default_param, proc)"
      end
    end

    def defv(name, *args, &block)
      if block_given?
        define_versioned_method(name, *args, &block)
      elsif args.size >= 1 && args[-1].is_a?(Proc)
        if args.size >= 2 && args[0].is_a?(String) && args[1].is_a?(Proc)
          define_versioned_method(name, *args)
        elsif args.size == 1
          define_versioned_method(name, nil, args[0])
        else
          define_versioned_method(name, *args)
        end
      else
        raise ArgumentError, "defv 需要 block 或 (default_param, proc)"
      end
    end

    def get_versioned_method(name, signature = nil)
      versions = _method_versions[name]
      return nil unless versions

      sig = signature || versions[:__latest__]
      return nil unless sig

      versions[sig]
    end

    def call_versioned(name, signature = nil, *args, &block)
      vm = get_versioned_method(name, signature)
      raise NameError, "方法 `#{name}` 版本 `#{signature || 'latest'}` 不存在" unless vm

      vm.call(*args, &block)
    end

    def method_versions(name)
      versions = _method_versions[name] || {}
      versions.reject { |k, _| k == :__latest__ }.transform_values(&:to_s)
    end

    def versioned_methods
      _method_versions.keys
    end

    def version_history(name)
      return [] unless _method_versions[name]

      _method_versions[name]
        .reject { |k, _| k == :__latest__ }
        .map { |sig, vm| { signature: sig, timestamp: vm.timestamp, method: vm } }
        .sort_by { |h| h[:timestamp] }
    end

    def rollback_to(name, signature)
      versions = _method_versions[name]
      raise NameError, "方法 `#{name}` 不存在" unless versions
      raise KeyError, "签名 `#{signature}` 不存在" unless versions[signature]

      versions[:__latest__] = signature
      signature
    end

    def remove_version(name, signature)
      versions = _method_versions[name]
      return false unless versions&.key?(signature)

      if versions.reject { |k, _| k == :__latest__ }.size <= 1
        raise "不能删除方法 `#{name}` 的唯一版本"
      end

      versions.delete(signature)

      if versions[:__latest__] == signature
        latest = versions.reject { |k, _| k == :__latest__ }.keys.last
        versions[:__latest__] = latest
      end

      true
    end

    def clear_versions(name)
      _method_versions.delete(name)
      if method_defined?(name)
        remove_method(name)
      end
      if singleton_class.method_defined?(name)
        singleton_class.remove_method(name)
      end
    end

    private

    def _register_version(name, signature: nil, body:)
      sig = signature || _generate_signature(name)

      if _method_versions[name]&.key?(sig)
        raise ArgumentError, "方法 `#{name}` 的签名 `#{sig}` 已存在"
      end

      versioned = VersionedMethod.new(
        name: name,
        signature: sig,
        body: body,
        module_ref: self
      )

      _method_versions[name] ||= {}
      _method_versions[name][sig] = versioned
      _method_versions[name][:__latest__] = sig

      # 安装实例方法调度器（首次定义时）
      unless method_defined?(name) || private_method_defined?(name)
        _install_instance_dispatcher(name)
      end

      # 安装模块方法调度器（首次定义时）
      unless singleton_class.method_defined?(name)
        _install_module_dispatcher(name)
      end

      sig
    end

    def _generate_signature(name)
      SIGNATURE_COUNTER[name] += 1
      "#{name}_v#{SIGNATURE_COUNTER[name]}_#{Time.now.to_i}"
    end

    def _method_versions
      VERSION_REGISTRY[self] ||= {}
    end

    # 实例方法调度器：obj.a 调用时路由到最新版本
    def _install_instance_dispatcher(name)
      define_method(name) do |*args, &block|
        mod = self.class.ancestors.find { |m| m.respond_to?(:get_versioned_method) }
        mod ||= self.singleton_class.ancestors.find { |m| m.respond_to?(:get_versioned_method) }

        versions = MonkeyPatch::VERSION_REGISTRY[mod]&.[](name)
        unless versions
          raise NoMethodError, "未找到版本化方法 `#{name}`"
        end

        latest_sig = versions[:__latest__]
        latest = versions[latest_sig]

        unless latest
          raise NoMethodError, "方法 `#{name}` 没有可用版本"
        end

        latest.call(*args, &block)
      end
    end

    # 模块方法调度器：A.a 调用时路由到最新版本
    def _install_module_dispatcher(name)
      singleton_class.send(:define_method, name) do |*args, &block|
        # 模块方法直接在当前模块上调用 call_versioned
        call_versioned(name, nil, *args, &block)
      end
    end
  end

  # 实例方法接口
  def call_version(name, signature = nil, *args, &block)
    mod = self.class.ancestors.find { |m| m.respond_to?(:call_versioned) }
    mod&.call_versioned(name, signature, *args, &block)
  end
end


# ============================================================
# 旧版本MonkeyPatch
# ============================================================

class Object
  attr_accessor :main_version, :versions
  
  def versions
    @versions ||= []
  end

  def versions= newver
    @versions ||= []
    @versions << newver unless @versions.include?(newver)
    @main_version = newver
    return newver
  end

  def revise method1,method2
    alias_method "tempfunc1",method1
    alias_method "tempfunc2",method2
    alias_method method1, "tempfunc2"
    alias_method method2, "tempfunc1"
  end
  
  def compize klass=nil
    return self.methods - self.class.superclass.instance_methods if klass.nil?
    return self.methods - klass.instance_methods
  end
  
  def verize name, tag=nil
    tag = Time.new.strftime("%Y%m%d%H%M%S") unless tag
    new_name, old_name = "#{name}_#{tag}",name
    alias_method new_name, old_name
  end
  
  def verize_all tag=nil
    tag = Time.new.strftime("%Y%m%d%H%M%S") unless tag
    unique_methods.each do|um|
      new_name, old_name = "#{um}_#{tag}", um
      alias_method new_name, old_name
    end
  end
  
  def unique_methods
    self.methods - self.class.superclass.instance_methods
  end

  def defm name, &block
    @____ ||= Hash.new
    @____[name] = block
  end
  
  def callm name, *args
    @____[name].call(*args)
  end
end

module Kernel
  def defp name, &block
    @____ ||= Hash.new
    @____[name] = block
  end
  
  def callp name, *args
    @____[name].call(*args)
  end
end
