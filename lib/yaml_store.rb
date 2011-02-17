require 'ostruct'
require 'yaml'

class YamlStore
  class << self
    attr_accessor :load_paths
    
    def load_paths
      @load_paths ||= Set.new 
    end

    def from(key)
      load_paths.each do |path|
        filename = File.join(path, key + '.yml')

        if File.exist?(filename)
          return new(YAML.load(File.read(filename)))
        end
      end  

      raise "YamlStore for #{key} not found!"
    end
  end

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
  
  module EvalBased
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
  
    def fetch(all_or_first=:all)
      filter = conditions.empty?? 'true' : conditions.join(' && ')
      reset_conditions!
    
      method = all_or_first == :all ? :select : :detect
      records.send(method) do |record|
        eval(filter)
      end
    end
  end
    
  include EvalBased unless $YAMLSTORE_BENCHMARK
  
  def each(*args, &block);    fetch.each(*args, &block); end
  def map(*args, &block);     fetch.map(*args, &block);  end  
  def collect(*args, &block); fetch.map(*args, &block);  end
  def first;                  fetch(:first);             end
  
  class Record < OpenStruct
    def id; key; end
    def has_property?(property)
      @table.has_key?(property.to_sym)
    end
  end
end
