$: << './lib'
require 'oddball'

results = Raveld::Oddball.discover_az_mapping([
  {:aws_access_key => 'key1',
   :aws_secret_key => 'secret1',},
  {:aws_access_key => 'key2',
   :aws_secret_key => 'secret2'},
  {:aws_access_key => 'key3',
   :aws_secret_key => 'secret3'}])
  #:endpoint => 'ec2.us-west-2.amazonaws.com')

puts results
