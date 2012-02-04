module Raveld
  class Ec2
    def initialize(aws_access_key, aws_secret_key, options = Hash.new)
      @aws_access_key = aws_access_key
      @aws_secret_key = aws_secret_key
      @options = options
    end
    
    def describe_spot_price_history(options = Hash.new)
      params = Hash.new
      params['StartTime'] = utc_iso8601(options[:start_time]) if options[:start_time]
      params['EndTime'] = utc_iso8601(options[:end_time]) if options[:end_time]
      params['InstanceType.1'] = options[:instance_type] if options[:instance_type]
      params['AvailabilityZone'] = options[:availability_zone]
      
      params['Action'] = 'DescribeSpotPriceHistory'
      params['Version'] = '2011-12-15'
      
      r = RaveldAws::Request.new(@options[:endpoint] || 'ec2.amazonaws.com', params, @aws_access_key, @aws_secret_key)
      r.execute
    end
    
    def utc_iso8601(time)
      time.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
    end
  end
end