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
  # Returns true or false depending on whether the list of photos can match with
  # this pattern if reordered appropriately.
  #
  def match?(photos)
    return false unless photos.count == photos_used
    photo_orientations = photos.map(&:orientation)

    # free shows how many photos of a given orientation are not accounted for
    # (that is, free to satisfy an "a" element). If any value of free is
    # negative, that means that there are too few photos to satisfy the pattern,
    # so nil is returned.
    [ :h, :v ].each do |o|
      return false if photo_orientations.count(o) < @pattern.count(o)
    end
    return true
  end
end


