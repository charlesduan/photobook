class Photobook
  class LayoutManager

    def initialize(data)
      @layouts = {}
      parse(data)
    end
    attr_reader :layouts

    def parse(data)
      case data
      when Hash
        data.each do |name, values|
          @layouts[name] = Layout.new(name, values)
        end
      when /\n/
        parse(YAML.load(data))
      else
        parse(YAML.load_file(data))
      end
    end

    def layout_for(name)
      return @layouts[name.to_s]
    end

  end
end
