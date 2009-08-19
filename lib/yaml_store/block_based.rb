class YamlStore
  module BlockBased
    class Condition
      attr_accessor :block
      attr_accessor :negated
      @negated = false
      
      def initialize(&block)
        self.block = block
      end
      
      def negated?
        @negated == true
      end
      
      def run(record)
        result = block.call(record)
        negated? ? !result : result
      end
    end
    
    def having(property, value=:any)
      case value
      when :any
        conditions << Condition.new { |record| record.has_property?(property) }
      when /^(<|<=|>|>=|!=|=)\s*(\d+\.?\d*)$/ # equality and comparison statements
        comparator = $1
        comparator *= 2 if comparator == '='
        operand    = $2.to_f
        conditions << Condition.new { |record| Numeric === record.send(property) && record.send(property).to_f.send(comparator, operand) }
      when Regexp
        conditions << Condition.new { |record| (record.send(property) || '') =~ value }
      when Array
        conditions << Condition.new { |record| value.include?(record.send(property)) }
      else
        conditions << Condition.new { |record| record.send(property) == value }
      end
    
      self  
    end
  
    def not_having(property, value=:any)
      having(property, value)
      conditions.last.negated = true
      self
    end 
    
    def fetch
      result = []
      records.each do |record|
        passes = conditions.inject(true) do |boolean, condition|
          boolean & condition.run(record)
        end
        
        result << record if passes
      end
      
      reset_conditions!
      result
    end
  end
end