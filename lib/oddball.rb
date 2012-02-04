require 'raveld_aws'

module Raveld
  class Oddball
    def self.discover_az_mapping(keys, options = Hash.new)
      end_time = Time.now.utc() - 3600
      start_time = end_time - 3600 * 24
      amaps = Hash.new
      keys.each do |key|
        amaps[key[:aws_access_key]] = cost_map(key[:aws_access_key], key[:aws_secret_key], start_time, end_time, options)
      end
      c = amaps.values[0]
      (c.length - 1).times do |x|
        ((x + 1)..(c.length - 1)).each do |y|
          raise "two zones have same rates -- consider different or longer time frame" if(costs_match?(c.values[x], c.values[y]))
        end
      end
      results = Array.new
      master_costs = amaps.values[0]
      master_costs.keys.each do |az|
        results.push({amaps.keys[0] => az})
      end
      amaps.keys[1..-1].each do |a_key|
        master_costs.length.times do |index|
          amaps[a_key].each do |taz, costs|
            results[index][a_key] = taz if(costs_match?(master_costs.values[index], costs))
          end
        end
      end
      results
    end
    
  private
    def self.costs_match?(source, target)
      s_h = source.inject(Hash.new){|h, v| h[cost_unique_key(v)] = true; h}
      t_h = target.inject(Hash.new){|h, v| h[cost_unique_key(v)] = true; h}
      return s_h == t_h
    end
    
    def self.cost_unique_key(value)
      "[#{value[:instanceType]}][#{value[:productDescription]}][#{value[:spotPrice]}][#{value[:timestamp]}]"
    end
  
    def self.cost_map(aws_access_key, aws_secret_key, start_time, end_time, options = Hash.new)
      ec2 = Raveld::Ec2.new(aws_access_key, aws_secret_key, options)
      results = ec2.describe_spot_price_history(:start_time => start_time, :end_time => end_time)
      results = results['DescribeSpotPriceHistoryResponse'][:spotPriceHistorySet][:item]
      rmap = Hash.new
      results.each do |r|
        rmap[r[:availabilityZone]] = Array.new unless rmap[r[:availabilityZone]]
        rmap[r[:availabilityZone]].push(r)
      end
      rmap
    end
  end
end