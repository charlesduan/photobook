class Photobook
  class Positioner

    def initialize(io, global_params = {})
      @io = io
      @global_params = {
        'scale' => 72,
        'page_width' => 8 * 72,
        'page_height' => (10.5 * 72).to_i,
        'bleed' => (0.25 * 72).to_i
      }.merge(global_params)
    end

    def puts(str)
      @io.puts(str)
    end

    def write(str)
      @io.write(str)
    end

    def init_photos(photos)
      @photos = photos.dup
    end

    def next_photo
      raise "Photo list not initialized" unless @photos.is_a?(Array)
      if @photos.count == 1
        res = @photos.first
        @photos = nil
        return res
      end
      return @photos.shift
    end


    # 
    # Converts a relative dimension (usually from a layout specification) to an
    # absolute one.
    #
    def rel_to_dim(rel_size)
      return rel_size * @global_params['scale']
    end

    #
    # Computes the margin size based on the given parameters.
    #
    def margin_size(params)
      return rel_to_dim(params['margin'] || 0)
    end

    #
    # Computes the spacing size based on the given parameters.
    #
    def spacing_size(params)
      return rel_to_dim(params['spacing'] || 0)
    end

    #
    # Computes the relevant box size given a containing box's dimensions, the
    # direction of this box (:horiz or :vert), and given parameters. The
    # argument +index+ is the position of the box being computed relative to its
    # sibling boxes; +box_count+ is the total number of boxes.
    #
    # Only the dimension that changes is returned (so for :horiz the height is
    # returned, and for :vert the width is returned).
    #
    def box_size(params, width, height, direction, index, box_count)
      dim_to_adjust = (direction == :horiz ? width : height)

      sizes = params['sizes']
      return dim_to_adjust / box_count.to_f unless sizes

      unless sizes.is_a?(Array) && sizes.count == box_count
        raise ArgumentError, "Sizes parameter is not an array of correct size"
      end
      sizes.last += 1.0 - sizes.inject(:+)
      unless sizes.all? { |x| x >= 0.0 && x <= 1.0 }
        raise ArgumentError, "Sizes must be between 0 and 1"
      end

      return sizes[index] * dim_to_adjust

    end

    #
    # Computes the gravity for the current box, based on the 'gravity' parameter
    # given. If it is 'outer' then the gravity is distributed across
    #
    def compute_gravity(params, index, box_count)
      g = params['gravity']
      distrib_gravity = (box_count == 1 ? 0.5 : index.to_f / (box_count - 1))

      case g
      when nil then return 0.5
      when Numeric then return [ 0, g, 1 ].sort[1]
      when 'left', 'top' then return 0
      when 'right', 'bottom' then return 1
      when 'outer' then return distrib_gravity
      when 'center' then return 1 - distrib_gravity
      else return 0.5
      end
    end


    def grid(spec, width, height)
      rows, cols = spec.split(/\s*x\s*/).map(&:to_i)
      boxes([ cols ] * rows, width, height)
    end

    #
    # Lays out a set of boxes according to a spec.
    #
    def boxes(spec, width, height, direction = :vert, last_gravity = 0.5)
      params = @page_params.merge(spec.find { |x| x.is_a?(Hash) } || {})

      box(direction, width, height) do
        first = true
        spec = spec.reject { |x| x.is_a?(Hash) }
        spec.each_with_index do |item, index|
          space(spacing_size(params), direction) unless first
          first = false

          size = box_size(params, width, height, direction, index, spec.count)
          this_gravity = compute_gravity(params, index, spec.count)

          #
          # For a vertical box, the current gravity will position boxes
          # vertically and the inherited gravity will position them
          # horizontally. The opposite is true for a horizontal box.
          #
          if direction == :vert
            this_height, this_width, next_dir = size, width, :horiz
            horiz_gravity, vert_gravity = last_gravity, this_gravity
          else
            this_height, this_width, next_dir = height, size, :vert
            horiz_gravity, vert_gravity = this_gravity, last_gravity
          end

          item = [ true ] * item if item.is_a?(Integer)
          case item
          when Array
            boxes(item, this_width, this_height, next_dir, this_gravity)
          when true
            photo_box(
              next_photo(), this_width, this_height,
              horiz_gravity, vert_gravity
            )
          when Numeric
            space(rel_to_dim(item))
          else
            raise "Unknown boxes item #{item}"
          end
        end
      end
    end

    def make_page(group)
      init_photos(group.photos)
      @page_params = @global_params.merge(group.layout.params)

      margin = margin_size(@page_params)
      width = @global_params['page_width'] - 2 * margin
      height = @global_params['page_height'] - 2 * margin

      page(group, margin + @global_params['bleed']) do
        if @page_params['grid']
          grid(@page_params['grid'], width, height)
        elsif @page_params['boxes']
          boxes(@page_params['boxes'], width, height)
        else
          raise "Positioning information missing in layout #{group.layout.name}"
        end
      end

    end

    def make_document(photo_list)
      width = @global_params['page_width'] + 2 * @global_params['bleed']
      height = @global_params['page_height'] + 2 * @global_params['bleed']

      document(@global_params, width, height) do
        photo_list.groups.each do |group|
          make_page(group)
        end
      end
    end

  end
end
