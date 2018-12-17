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
    # Computes and allocates +total_size+ across the items in +allocations+,
    # which should be only ItemAllocation objects.
    #
    def allocate_sizes(params, allocations, total_size)
      sizes = params['sizes']
      sizes ||= [ 1.0 / allocations.count ] * allocations.count

      unless sizes.is_a?(Array) && sizes.count == allocations.count
        raise ArgumentError, "Sizes parameter is not an array of correct size"
      end
      sizes[-1] += 1.0 - sizes.inject(:+)
      unless sizes.all? { |x| x >= 0.0 && x <= 1.0 }
        raise ArgumentError, "Sizes must be between 0 and 1"
      end

      allocations.zip(sizes).each do |alloc, size|
        alloc.size = size * total_size
      end
    end

    #
    # Computes the gravity for the current box, based on the 'gravity' parameter
    # given. If it is 'outer' then the gravity is distributed across
    #
    def allocate_gravity(params, allocations)
      g = params['gravity']

      allocations.each_index do |i|
        next unless allocations[i].is_a?(ItemAllocation)
        allocations[i].gravity =
          case g
          when nil then 0.5
          when Numeric then [ 0, g, 1 ].sort[1]
          when 'left', 'top' then 0
          when 'right', 'bottom' then 1
          when 'outer' then distrib_gravity(allocations, i)
          when 'center' then 1 - distrib_gravity(allocations, i)
          else 0.5
          end
      end
    end

    def distrib_gravity(allocations, i)
      pre_size = allocations[0...i].map(&:size).inject(0.0, :+)
      post_size = allocations[(i+1)..-1].map(&:size).inject(0.0, :+)
      return pre_size.to_f / (pre_size + post_size)
    end

    def grid(spec, width, height)
      rows, cols = spec.split(/\s*x\s*/).map(&:to_i)
      boxes([ cols ] * rows, width, height)
    end

    class SpaceAllocation
      def initialize(positioner, size)
        @positioner = positioner
        @size = size
      end
      attr_accessor :size

      def apply(dir, other_size, other_gravity)
        @positioner.space(@size, dir)
      end
    end

    class ItemAllocation
      def initialize(positioner, box)
        @positioner = positioner
        @box = box
      end
      attr_accessor :size, :gravity
      def apply(dir, other_size, other_gravity)
        if dir == :horiz
          if @box.is_a?(Array)
            @positioner.boxes(@box, @size, other_size, :vert, @gravity)
          else
            @positioner.photo_box(
              @positioner.next_photo(), @size, other_size,
              @gravity, other_gravity
            )
          end
        else
          if @box.is_a?(Array)
            @positioner.boxes(@box, other_size, @size, :horiz, @gravity)
          else
            @positioner.photo_box(
              @positioner.next_photo(), other_size, @size,
              other_gravity, @gravity
            )
          end
        end
      end
    end

    def allocate(params, total_size, spec)
      total_spacing = 0.0
      total_items = 0
      default_spacing = spacing_size(params)
      allocations = []
      items = []

      #
      # First, determine the order of items to be placed within the box.
      spec.each do |item|
        case item
        when Integer, Array, true
          # For photos (true) and sub-boxes, insert a default spacer if the last
          # allocation was for an item. Then create the allocation for the item.
          if allocations.last.is_a?(ItemAllocation)
            total_spacing += default_spacing
            allocations.push(SpaceAllocation.new(self, default_spacing))
          end
          item = [ true ] * item if item.is_a?(Integer)
          alloc = ItemAllocation.new(self, item)
          allocations.push(alloc)
          items.push(alloc)
          total_items += 1

        when Numeric
          # For spacers, insert the spacer and update the total space.
          this_space = rel_to_dim(item)
          total_spacing += this_space
          allocations.push(SpaceAllocation.new(self, this_space))
        else
          raise "Unknown boxes item #{item.class}: #{item}"
        end
      end

      # Next, compute the space left and allocate it across the items.
      allocate_sizes(params, items, total_size - total_spacing)

      # Finally, allocate the gravity.
      allocate_gravity(params, allocations)
    end

    #
    # Lays out a set of boxes according to a spec.
    #
    def boxes(spec, width, height, direction = :vert, last_gravity = 0.5)
      params = @page_params.merge(spec.find { |x| x.is_a?(Hash) } || {})
      spacing = spacing_size(params)

      box(direction, width, height) do
        first = true
        spec = spec.reject { |x| x.is_a?(Hash) }
        allocations = allocate(
          params, direction == :vert ? height : width, spec
        )

        other_size = (direction == :vert ? width : height)
        allocations.each do |item|
          item.apply(direction, other_size, last_gravity)
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

    #
    # Computes the resolution of a photo crop that is as large as possible while
    # having the aspect ratio as given. Returns a two-element array of width and
    # height for the photo.
    #
    def fill_crop(photo, width, height)
      want_ratio = width.to_f / height
      if want_ratio * photo.height <= photo.width
        return [ (want_ratio * photo.height).round, photo.height ]
      else
        return [ photo.width, (photo.width / want_ratio).round ]
      end
    end

  end
end
