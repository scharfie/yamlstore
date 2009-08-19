require 'ostruct'
require 'yaml'

class YamlStore
  attr_accessor :records
  
  def initialize(yaml)
    @records = []
    
    if yaml.instance_of?(Array)
      yaml.each_with_index do |value, key|
        @records << YamlStore::Record.new({'key' => key}.merge(value))
      end  
    else
      yaml.each do |key, value|
        @records << YamlStore::Record.new({'key' => key}.merge(value))
      end
    end  
  end
  
  def conditions
    @conditions ||= []
  end
  
  def reset_conditions!
    @conditions = nil; conditions
  end
  
  def having(property, value=:any)
    case value
    when :any
      conditions << "record.has_property?(#{property.inspect})"
    when /^(<|<=|>|>=|!=|=)\s*(\d+\.?\d*)$/ # equality and comparison statements
      value = "=#{value}" if $1 == '=' # ensure two equal signs (to allow for '= 7.1')
      conditions << "(Numeric === record.#{property} && record.#{property}.to_f #{value})"
    when Regexp
      conditions << "(record.#{property} || '') =~ #{value.inspect}"  
    when Array
      conditions << "#{value.inspect}.include?(record.#{property})"
    else
      conditions << "record.#{property} == #{value.inspect}"
    end
    
    self  
  end
  
  def not_having(property, value=:any)
    having(property, value)
    conditions[-1] = "!(#{conditions[-1]})"
    self
  end
  
  def each(*args, &block);    fetch.each(*args, &block); end
  def map(*args, &block);     fetch.map(*args, &block); end  
  def collect(*args, &block); fetch.map(*args, &block); end  
  
  def fetch
    filter = conditions.join(' && ')
    reset_conditions!
    
    records.select do |record|
      eval(filter)
    end
  end
  
  class Record < OpenStruct
    def id; key; end
    def has_property?(property)
      @table.has_key?(property.to_sym)
    end
  end
end