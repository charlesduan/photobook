class Photobook::Layout
  def self.parse_layouts(file)
    return YAML.load_file(file).map do |pattern|
      Layout.new(pattern)
    end
  end

  def initialize(name, params)
    @name = name
    @params = params
    @pages_used = @params['pages'] || 1
    @pattern = @params['pattern'].split(//).map { |p|
      case p
      when /[hl]/i then :h
      when /[vp]/i then :v
      when /[a*]/i then :a
      else raise "Invalid pattern spec #{@params['pattern']}"
      end
    }
    @photos_used = @pattern.count
  end

  attr_reader :pages_used, :photos_used, :pattern, :name, :params

  #
  # Matches an array of photos against the pattern. If the photos cannot match
  # with this pattern, then returns nil. Otherwise, returns an array of photos
  # ordered in the way that this pattern expects.
  #
  def match(photos)
    return nil unless photos.count == photos_used
    photo_orientations = photos.map(&:orientation)

    # free shows how many photos of a given orientation are not accounted for
    # (that is, free to satisfy an "a" element). If any value of free is
    # negative, that means that there are too few photos to satisfy the pattern,
    # so nil is returned.
    free = {}
    [ :h, :v ].each do |o|
      free[o] = photo_orientations.count(o) - @pattern.count(o)
      return nil if free[o] < 0
    end

    photos = photos.dup
    res = []
    @pattern.each do |orientation|
      if orientation == :a
        if free[:h] == 0 then orientation = :v
        elsif free[:v] == 0 then orientation = :h
        else
          free[photos.first.orientation] -= 1
          res.push(photos.shift)
          next
        end
      end
      pos = photos.find_index { |p| p.orientation == orientation }
      res.push(photos.delete_at(pos))
    end
    raise "Uh oh" unless photos.empty? or res.include?(nil)
    return res
  end
end


