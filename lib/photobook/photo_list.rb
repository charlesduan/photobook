class Photobook

  class PhotoList

    def initialize(layout_manager, lines)
      @layout_manager = layout_manager
      @groups = []

      lines = lines.split(/\n/) if lines.is_a?(String)

      parse(lines.dup) do |photo|
        yield(photo)
      end
    end

    attr_reader :groups, :layout_manager

    def parse(lines)
      layout, params = parse_layout(lines)
      photos = []
      until lines.empty?
        line = lines.shift
        case line
        when /^-----$/ then break
        when /^\s*$/ then next
        when /\s+\((\w+)\)$/ then photos.push(Photo.new($`, $1.to_sym))
        else photos.push(Photo.new(line, yield(line)))
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

    def arrange
      @groups = @groups.map { |group|
        if group.layout then group
        else Arranger.new(@layout_manager, group.photos, group.params).arrange
        end
      }.flatten
    end

  end
end
