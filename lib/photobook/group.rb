class Photobook
  class Group
    def initialize(layout, photos, params = {})
      @layout = layout
      @params = params
      @photos = photos

      raise ArgumentError unless @params.is_a?(Hash)
      unless @photos.is_a?(Array) && !@photos.empty?
        raise "Photos may not be empty"
      end
      unless @layout.nil?
        raise ArgumentError unless @layout.is_a?(Layout)
        m = @layout.match(@photos)
        raise "PhotoList::Group's photos do not match its layout" if m.nil?
        if m != @photos
          warn("PhotoList::Group's photos are out of order; fixing")
          @photos = m
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
        res << "#{photo.name} (#{photo.orientation})\n"
      end
      res << "-----\n"
      return res
    end
  end

end