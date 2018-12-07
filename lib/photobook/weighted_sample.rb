class Photobook
  module WeightedSample

    def weighted_sample(enum, probability)
      loop do
        enum.each do |x|
          return x if rand < probability
        end
      end
    end

  end
end
