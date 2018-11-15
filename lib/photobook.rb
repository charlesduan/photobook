require 'yaml'

class Photobook
  def initialize(patterns, photos)
    @bests = []
    @photos = photos
    @position = 0
    @pattern_index = {}
    patterns.each do |pattern|
      (@pattern_index[pattern.photos_used] ||= []).push(pattern)
    end

    @best_option = nil
  end

  def arrange
    (0 ... @photos.count).each do |pos|
      @position = pos
      try_position
    end
    return @bests[@photos.count - 1]
  end

  def try_position
    @best_option = nil
    @pattern_index.keys.sort { |a, b| b <=> a }.each do |size|
      next if size > @position + 1
      try_patterns(size)
    end
    @bests[@position] = @best_option
  end

  def try_patterns(size)
    photos = get_slice(size)
    rest = get_best_for(size)
    patterns = @pattern_index[size]
    patterns.each do |pattern|
      try_pattern(pattern, photos, rest)
    end
  end

  def try_pattern(pattern, photos, rest)
    res = pattern.match(photos)
    return unless res
    new_score = rest[:score] + pattern.score
    return unless @best_option.nil? or new_score > @best_option[:score]
    @best_option = {
      :score => new_score,
      :layout => rest[:layout] + [ { :pattern => pattern, :photos => res } ]
    }
  end

  def get_slice(size)
    start = @position - size + 1
    raise "Invalid slice size #{size} for position #@position" if start < 0
    @photos[start, size]
  end

  def get_best_for(size)
    start = @position - size
    return { :score => 0, :layout => [] } if start < 0
    return @bests[start]
  end
end

require 'photobook/photo'
require 'photobook/layout'
require 'photobook/layout_manager'
require 'photobook/photo_list'
require 'photobook/arranger'
