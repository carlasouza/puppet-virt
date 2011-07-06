#!/usr/bin/env ruby


prefixes = {
  'xen' => '00:16:3E',
}

def random_hex
  rand(15).to_s(16).upcase
end

type = ARGV.shift
unless prefixes[type]
  puts "Usage: #{File.basename(__FILE__)} <type>"
  puts "Where known types are: #{prefixes.keys.join(', ')}"
  exit 1
end


puts "#{prefixes[type]<<'.'<<(0..(5-prefixes[type].split(':').length)).collect{ random_hex + random_hex }.join(':')}"
