class Photobook::Photo

  def initialize(name, width, height, exif_orientation = nil)
    @name = name
    @width = width
    @height = height
    @exif_orientation = exif_orientation
  end

  def to_s
    o = [ nil, 1 ].include?(@exif_orientation) ? "" : ",#@exif_orientation"
    return "#@name (#{@width}x#{@height}#{o})"
  end

  attr_reader :name, :exif_orientation, :width, :height

  def orientation
    return @width > @height ? :h : :v
  end
end


