require 'exifr/jpeg'

class Photobook
  class PhotoList

    include WeightedSample

    def initialize(layout_manager, lines)
      @layout_manager = layout_manager
      @groups = []
      @dirty = false

      lines = lines.split(/\n/) if lines.is_a?(String)

      parse(lines.dup)
    end

    attr_reader :groups, :layout_manager

    def dirty?
      @dirty
    end

    def parse(lines)
      layout, params = parse_layout(lines)
      photos = []
      until lines.empty?
        line = lines.shift
        case line
        when /^-----$/ then break
        when /^\s*$/ then next
        else photos.push(Photo.parse(line))
        end
      end
      @groups.push(Group.new(layout, photos, params)) unless photos.empty?
      parse(lines) unless lines.empty?
    end

    def parse_layout(lines)
      layout = nil
      until lines.empty?
        case lines.first
        when /^\s*$/, /^-----$/
          lines.shift
          next
        when /^PAGE$/
          lines.shift
          break
        when /^PAGE\s+/
          layout = @layout_manager.layout_for($')
          warn("Layout #{layout_name} is unknown") unless layout
          lines.shift
          break
        else
          return nil, {}
        end
      end

      params = {}
      until lines.empty?
        break unless (lines[0] =~ /^\s+(\w[^:]*):\s*/)
        params[$1] = $'
        lines.shift
      end
      return layout, params
    end

    def to_s
      @groups.map { |x| x.to_s }.join("\n")
    end

    def needs_arranging
      @groups.any? { |group| !group.layout }
    end

    def arrange
      @groups = @groups.map { |group|
        if group.layout
          group
        else
          @dirty = true
          Arranger.new(@layout_manager, group.photos, group.params).arrange
        end
      }.flatten
    end

    def add_backgrounds(photos, overwrite = false)
      photos = photos.dup
      @groups.each do |group|
        next if overwrite || group.background
        next if group.layout.params['nobackground']
        photo = photos.delete_at(weighted_sample(0...photos.count, 0.3))
        group.background = photo
        photos.push(photo)
        @dirty = true
      end
    end

    def sort_by_date
      @dirty = true
      photos = @groups.map { |group| group.photos }.flatten.sort_by { |photo|
        EXIFR::JPEG.new(photo.name).date_time || Time.at(File.mtime(photo.name))
      }
      @groups = [ Group.new(nil, photos, {}) ]
    end

  end
end
