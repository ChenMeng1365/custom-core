#!/usr/bin/env ruby
# encoding: utf-8

require 'io/console'

class ProgressBar
  # 预设主题
  THEMES = {
    classic: { fill: '█', empty: '░', left: '[', right: ']', arrow: '>' },
    modern:  { fill: '●', empty: '○', left: '', right: '', arrow: '▶' },
    blocks:  { fill: '■', empty: '□', left: '│', right: '│', arrow: '▶' },
    dots:    { fill: '◉', empty: '◎', left: '⟨', right: '⟩', arrow: '→' },
    minimal: { fill: '=', empty: '-', left: '[', right: ']', arrow: '>' },
    hearts:  { fill: '♥', empty: '♡', left: ' ', right: ' ', arrow: '💕' }
  }

  attr_reader :total, :current, :start_time

  def initialize(total, title: "Processing", theme: :modern, width: 40, show_percentage: true, show_eta: true, color: true)
    @total = total
    @current = 0
    @title = title
    @theme = THEMES[theme] || THEMES[:modern]
    @width = width
    @show_percentage = show_percentage
    @show_eta = show_eta
    @color = color
    @start_time = Time.now
    @last_update = 0
    @mutex = Mutex.new
    
    # ANSI 颜色代码
    @colors = {
      reset:   "\e[0m",
      bold:    "\e[1m",
      green:   "\e[32m",
      yellow:  "\e[33m",
      blue:    "\e[34m",
      magenta: "\e[35m",
      cyan:    "\e[36m",
      gray:    "\e[90m"
    }
    
    # 隐藏光标
    print "\e[?25l"
  end

  # 更新进度
  def update(step = 1)
    @mutex.synchronize do
      @current += step
      @current = @total if @current > @total
      refresh if should_refresh?
    end
  end

  # 直接设置进度
  def set(value)
    @mutex.synchronize do
      @current = [[value, @total].min, 0].max
      refresh
    end
  end

  # 完成进度条
  def finish(message: "Done!")
    @mutex.synchronize do
      @current = @total
      refresh
      puts  # 换行
      show_cursor
      puts colorize(message, :green) unless message.empty?
    end
  end

  # 显示统计信息
  def stats
    elapsed = Time.now - @start_time
    rate = @current / elapsed rescue 0
    {
      total: @total,
      current: @current,
      percentage: (@current.to_f / @total * 100).round(1),
      elapsed: format_time(elapsed),
      eta: format_time(eta),
      rate: rate.round(2)
    }
  end

  # 清理资源
  def dispose
    show_cursor
  end

  private

  def should_refresh?
    now = Time.now.to_f
    return false if now - @last_update < 0.05  # 限制刷新率 20fps
    @last_update = now
    true
  end

  def refresh
    percentage = @current.to_f / @total
    filled = (percentage * @width).round
    empty = @width - filled

    bar = @theme[:fill] * filled + 
          (@current < @total ? @theme[:arrow] : @theme[:fill]) + 
          @theme[:empty] * [empty - 1, 0].max

    # 构建输出字符串
    parts = []
    
    # 标题
    parts << colorize(sprintf("%-15s", @title), :bold)
    
    # 进度条
    bar_color = percentage >= 1.0 ? :green : (percentage > 0.5 ? :cyan : :yellow)
    parts << "#{@theme[:left]}#{colorize(bar, bar_color)}#{@theme[:right]}"
    
    # 百分比
    if @show_percentage
      parts << colorize(sprintf("%6.1f%%", percentage * 100), :magenta)
    end
    
    # 计数
    parts << colorize("[#{@current}/#{@total}]", :gray)
    
    # ETA
    if @show_eta && @current > 0 && @current < @total
      parts << colorize("ETA: #{format_time(eta)}", :blue)
    end

    # 清除行并输出
    print "\r\e[K" + parts.join(' ')
    $stdout.flush
  end

  def eta
    return 0 if @current == 0
    elapsed = Time.now - @start_time
    remaining = @total - @current
    (elapsed / @current) * remaining
  end

  def format_time(seconds)
    return "0s" if seconds < 1
    if seconds < 60
      "#{seconds.round}s"
    elsif seconds < 3600
      "#{(seconds / 60).floor}m #{(seconds % 60).round}s"
    else
      "#{(seconds / 3600).floor}h #{((seconds % 3600) / 60).floor}m"
    end
  end

  def colorize(text, color)
    return text unless @color
    "#{@colors[color]}#{text}#{@colors[:reset]}"
  end

  def show_cursor
    print "\e[?25h"
  end
end

# 辅助方法（用于示例中的颜色输出）
def colorize(text, color)
  colors = { green: "\e[32m", yellow: "\e[33m", gray: "\e[90m", reset: "\e[0m" }
  "#{colors[color]}#{text}#{colors[:reset]}"
end

=begin
  # ==================== 使用示例 ====================
  puts "🚀 Ruby Fancy Progress Bar Demo"
  puts "=" * 50

  # 示例 1: 基础用法
  puts "\n📊 示例 1: 基础文件处理"
  bar = ProgressBar.new(100, title: "Downloading", theme: :modern)
  100.times do |i|
    sleep(0.03)  # 模拟工作
    bar.update
  end
  bar.finish(message: "✅ 下载完成!")

  # 示例 2: 不同主题展示
  puts "\n🎨 示例 2: 主题展示"
  [:classic, :blocks, :dots, :minimal].each do |theme_name|
    bar = ProgressBar.new(50, title: theme_name.to_s, theme: theme_name, width: 30)
    50.times do
      sleep(0.02)
      bar.update
    end
    bar.finish(message: "")
  end

  # 示例 3: 批量任务处理（带错误处理）
  puts "\n📁 示例 3: 批量文件处理"
  files = (1..20).map { |n| "file_#{n}.txt" }
  bar = ProgressBar.new(files.size, title: "Processing", theme: :hearts, color: true)
  processed = []
  files.each do |file|
    sleep(0.1)  # 模拟处理时间
    processed << file
    bar.update
    # 模拟偶尔的错误
    if rand < 0.1
      print "\n⚠️  #{colorize("警告: #{file} 处理异常", :yellow)}"
    end
  end
  bar.finish(message: "✨ 处理了 #{processed.size} 个文件")

  # 示例 4: 嵌套进度条（多阶段任务）
  puts "\n🏗️  示例 4: 多阶段构建任务"
  phases = [
    { name: "Compiling", items: 30 },
    { name: "Testing", items: 20 },
    { name: "Packaging", items: 15 }
  ]
  phases.each do |phase|
    puts "\n阶段: #{phase[:name]}"
    bar = ProgressBar.new(phase[:items], title: phase[:name], theme: :modern)
    phase[:items].times do
      sleep(0.05)
      bar.update
    end
    bar.finish(message: "")
  end
  puts colorize("🎉 所有阶段完成!", :green)

  # 示例 5: 实时速度显示（大数据处理）
  puts "\n⚡ 示例 5: 大数据处理（带实时统计）"
  total_items = 1000
  bar = ProgressBar.new(total_items, title: "BigData", theme: :blocks, width: 50)
  total_items.times do |i|
    sleep(0.01)  # 模拟快速处理
    # 每 100 个显示一次统计
    if i % 100 == 0 && i > 0
      s = bar.stats
      print "\n   #{colorize("速度: #{s[:rate]} items/s | 已用: #{s[:elapsed]} | 剩余: #{s[:eta]}", :gray)}"
    end
    bar.update
  end
  bar.finish

  # 示例 6: 手动控制进度（非均匀任务）
  puts "\n🎮 示例 6: 手动进度控制（非均匀任务）"
  bar = ProgressBar.new(100, title: "Uploading", theme: :dots)
  # 模拟不同大小的文件上传
  uploads = [10, 25, 5, 30, 20, 10]
  uploads.each_with_index do |size, idx|
    sleep(0.3)  # 模拟上传时间
    bar.set(bar.current + size)
    print "\n   上传了 chunk_#{idx + 1}.bin (#{size}MB)"
  end
  bar.finish(message: "上传完成")
  # 确保光标显示
  print "\e[?25h"
  puts "\n" + "=" * 50
  puts "✨ 所有演示完成! 你可以复制 ProgressBar 类到你的项目中使用。"
=end