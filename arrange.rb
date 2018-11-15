#!/usr/bin/ruby

require 'yaml'

class PhotoArranger
end

__END__

patterns = [
  PagePattern.new('h', 1, 10),
  PagePattern.new('v', 1, 10),
  PagePattern.new('hh', 1, 20),
  PagePattern.new('vv', 1, 20),
  PagePattern.new('hvv', 1, 80),
  PagePattern.new('hhh', 1, 80),
  PagePattern.new('vvvv', 1, 100),
  PagePattern.new('hvvh', 1, 100)
]

photos = (1..50).map { |x|
  Photo.new("photo-%02d" % x, rand > 0.5 ? :h : :v)
}

pa = PhotoArranger.new(patterns, photos)
res = pa.arrange
res[:layout].each do |pair|
  puts "Group:"
  puts "  Pattern: #{pair[:pattern].pattern}"
  puts "  Photos:  #{pair[:photos].join(", ")}"
end
