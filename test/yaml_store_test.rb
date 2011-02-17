require 'test_helper'

class YamlStoreTest < Test::Unit::TestCase
  def assert_keys(expected_keys, results)
    actual_keys = results.map { |e| e.key }
    assert_equal expected_keys, actual_keys
  end

  context 'DSL' do
    should "load test/data/cities.yml" do
      YamlStore.load_paths = [
        File.join(File.dirname(__FILE__), "data")
      ]

      @store = nil

      assert_nothing_raised do
        @store = YamlStore.from('cities')
      end
      
      assert_equal 3, @store.records.length
    end
  end

  context 'with hash' do
    setup do
      @store = YamlStore.new(YAML.load(SampleData.hash))
    end

    should "test first" do
      assert_equal 'A', @store.first.key
    end
    
  
    should "test having" do
      assert_keys %w(A C), @store.having(:photo, true)
      assert_keys %w(B D), @store.having(:photo, false)
      assert_keys %w(A D), @store.having(:flag)
      assert_keys %w(B),   @store.having(:age,   '<= 21')
      assert_keys %w(C),   @store.having(:age,   '> 21')
      assert_keys %w(A),   @store.having(:wage,  '= 5.65')
      assert_keys %w(B C), @store.having(:first, /^Jo/)
    end
  
    should "test not_having" do
      assert_keys %w(B D), @store.not_having(:photo, true)
      assert_keys %w(C),   @store.not_having(:last)
      assert_keys %w(D),   @store.not_having(:age)
      assert_keys %w(A D), @store.not_having(:first, /^Jo/)
    end
  
    should "test having/not_having chain" do
      assert_keys %w(A B C), @store.having(:first).not_having(:first, 'Chris')
      assert_keys %w(A B),   @store.having(:first).not_having(:first, ['Chris', 'Joe'])
      assert_keys %w(B D),   @store.having(:first).not_having(:first, /^\w{3}$/)
    end
  end
  
  context 'ordered map' do
    setup do
      @store = YamlStore.new(YAML.load(SampleData.ordered_map))
    end
  
    should "test having" do
      results = @store.having(:photo, true).fetch.map { |e| e.id }
      assert results.include?('A')
      assert results.include?('C')
    end
  end

  context 'array' do
    setup do
      @store = YamlStore.new(YAML.load(SampleData.array))
    end
  
    should "test having" do
      results = @store.having(:photo, true).fetch.map { |e| e.id }
      assert results.include?('A')
      assert results.include?('C')
    end
  end
end

class SampleData
  def self.ordered_map
<<-YAML
--- !omap
- D:
    photo: false
- A:
    photo: true
- B: 
    photo: false
- C: 
    photo: true
YAML
  end

  def self.array
<<-YAML
- key: D
  photo: false
- key: A
  photo: true
- key: B
  photo: false
- key: C 
  photo: true
YAML
  end  

  def self.hash
<<-YAML
D:
  photo: false
  first: Chris
  last:  Scharf
  flag:  1
A:
  photo: true
  first: Bob
  last:  Smith
  flag:  1
  age:   nil
  wage:  5.65
B: 
  photo: false
  first: John
  last:  Jones
  age:   14
C: 
  photo: true
  first: Joe
  age:   95
YAML
  end
end
