class Photobook::Photo

  def initialize(name, orientation)
    @name = name
    @orientation = orientation
    raise 'Invalid orientation' unless [ :h, :v ].include?(orientation)
  end

  def to_s
    "[#{@name} #{@orientation}]"
  end

  attr_reader :name, :orientation
end


