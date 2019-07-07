class Photobook
  class Group
    def initialize(layout, photos, params = {})
      @layout = layout
      @params = params
      @photos = photos.dup

      raise ArgumentError unless @params.is_a?(Hash)
      unless @photos.is_a?(Array) && !@photos.empty?
        raise "Photos may not be empty"
      end
      unless @layout.nil?
        raise ArgumentError unless @layout.is_a?(Layout)
        unless @layout.match?(@photos)
          raise "PhotoList::Group's photos do not match its layout"
        end
      end
    end

    attr_reader :layout, :params, :photos

    def to_s
      res = ""
      res << "PAGE" << (@layout ? " #{@layout.name}" : "") << "\n"
      unless @params.empty?
        @params.each { |k, v| res << "  #{k}: #{v}\n" }
        res << "\n"
      end
      @photos.each do |photo|
        res << "#{photo}\n"
      end
      res << "-----\n"
      return res
    end

    def background
      if !@background && @params['background']
        @background = Photo.parse(@params['background'])
      end
      return @background
    end

    def background=(photo)
      raise ArgumentError unless photo.is_a?(Photo)
      @background = photo
      @params['background'] = photo.to_s
      return photo
    end

    # Returns a list of photos arranged to match this group.
    def arranged_photos
      raise 'Cannot arrange a photo group with no layout' unless @layout
      pattern = @layout.pattern
      photo_orientations = @photos.map(&:orientation)
      free = {}
      [ :h, :v ].each do |o|
        free[o] = photo_orientations.count(o) - pattern.count(o)
        raise "Unexpectedly non-matching layout" if free[o] < 0
      end

      photos = @photos.dup
      res = []
      pattern.each do |orientation|
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
      raise "Unexpectedly found extra photos" unless photos.empty?
      return res
    end

  end
end
