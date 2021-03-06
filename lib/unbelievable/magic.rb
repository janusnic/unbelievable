# Copyright (c) 2013 Michael Dvorkin
#
# Unbelievable is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php

$unbelievable = { code: [], missing: [], passthrough: false, debug: false }

module Unbelievable
  extend self
  attr_accessor :style
  STYLES = [ :random, :todo, :secret, :lorem, :haiku ]

  def generate(code, style = nil)
    with_method_missing do
      style ||= @style || :random
      unless STYLES.include?(style)
        raise ArgumentError, "style must be one of #{STYLES.inspect} but not #{style.inspect}"
      else
        style = (STYLES - [:random]).sample if style == :random
        chars = code.unpack("C*")
        encoded = sprintf("%03o" * chars.size, *chars).unpack("C*").map{ |n| n - 45 }
        generator = Object.const_get("#{self}::#{style.capitalize}")
        generator.new.story(encoded)
      end
    end
  end

  private

  def with_method_missing(&blk)
    $unbelievable[:passthrough] = true
    yield
  ensure
    $unbelievable[:passthrough] = false
  end
end

def method_missing(name, *args)
  return super if $unbelievable[:passthrough] || defined?(::IRB) || defined?(::Pry)

  if $unbelievable[:debug]
    puts "method_missing: #{self.class.inspect} => #{self.inspect}"
    puts "method_missing: #{name}: #{args}, #{$unbelievable[:missing].inspect}"
  end

  if args.empty? && $unbelievable[:missing].any?
    $unbelievable[:code].concat($unbelievable[:missing].reverse)
    $unbelievable[:missing].clear
  end
  $unbelievable[:missing] << (name.to_s.size - 1).to_s
end

def Object.const_missing(name)
  send(name.downcase)
end

if !defined?(::IRB) && !defined?(::Pry)
  at_exit do
    if $unbelievable[:debug]
      puts "miss: " << $unbelievable[:missing].reverse.inspect
      puts "code: " << $unbelievable[:code].inspect
      puts "scan: " << $unbelievable[:code].join.scan(/.../).inspect
      puts "pack: " << $unbelievable[:code].join.scan(/.../).map { |o| o.bytes.map { |n| n - 2 }.pack("C*") }.inspect
      puts "i(8): " << $unbelievable[:code].join.scan(/.../).map { |o| o.bytes.map { |n| n - 2 }.pack("C*").to_i(8) }.inspect
    end

    $unbelievable[:code].concat($unbelievable[:missing].reverse)
    eval $unbelievable[:code].join.scan(/.../).map { |o| o.bytes.map { |n| n - 2 }.pack("C*").to_i(8).chr }.join
  end
end
