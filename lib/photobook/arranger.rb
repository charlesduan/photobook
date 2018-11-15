class Photobook
  class Arranger

    def initialize(layout_manager, photos, params = {})
      @layout_manager, @photos, @params = layout_manager, photos, params
      @save_params = @params.reject { |k, v| %w(max_pages).include?(k) }
    end

    def make_group(layout, photos)
      return nil unless layout && photos
      Group.new(layout, photos, @save_params)
    end

    def arrange
      @memo = []

      0.upto(@photos.count - 1) do |size|
        @memo[size] = select_best_arrangements(arrange_subset(size))
      end

      return @memo.last.first
    end

    # Returns an array of two-element arrays, for which the first element
    # is a list of matches and the second a new match to add to that list.
    def arrange_subset(upper)
      res = all_matches(@photos[0..upper]).map { |x| [ [], x ] }
      1.upto(upper) do |lower|
        next if @memo[lower - 1].empty?
        res.concat(@memo[lower - 1].product(all_matches(@photos[lower..upper])))
      end
      return res
    end

    # arrangements will be an array of two-element arrays, for which the first
    # element is a list of matches and the second a new match to add to that
    # list.
    def select_best_arrangements(arrangements)
      if @params['max_pages']
        arrangements = arrangements.select { |x|
          x[0].count < @params['max_pages']
        }
      end
      arrangements = arrangements.sort_by do |arr| -score_arrangement(arr) end
      return choose_arrangements(arrangements, 3).map(&:flatten)
    end

    def score_arrangement(arr)
      return arr[1].layout.pattern.count if arr[0].empty?
      prev_layout, this_layout = arr[0].last.layout, arr[1].layout

      score = (prev_layout.pattern.count - this_layout.pattern.count).abs
      score = -3 if score == 0
      score -= 10000 if prev_layout == this_layout
      score -= 10 if prev_layout.pattern == this_layout.pattern
      score -= arr[0].count { |group| group.layout == this_layout }
      return score
    end

    def choose_arrangements(arrangements, count)
      return arrangements if arrangements.count <= count
      res = []
      count.times do res.push(choose_one_arrangement(arrangements)) end
      return res
    end

    def choose_one_arrangement(arrangements)
      arrangements.each_index do |i|
        return arrangements.delete_at(i) if rand < 0.5
      end
      return arrangements.first
    end

    #
    # Compares the given array of photos against all layouts and produces an
    # array of Group objects representing the matches.
    #
    def all_matches(subset)
      @layout_manager.layouts.values.map { |layout|
        res = layout.match(subset)
        make_group(layout, res)
      }.compact
    end

  end
end
