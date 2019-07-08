class Photobook
  class LayoutManager

    # Path for layout specifications.
    LAYOUT_DIR = File.expand_path('../../../data/layouts', __FILE__)

    #
    # Searches for layout specification files in the current directory and in
    # LAYOUT_DIR. The ".yaml" extension may be omitted. The found file name is
    # returned, or nil if no file is found.
    #
    def self.find_layout_file(name)
      tries = [ name, "#{name}.yaml" ]
      tries += tries.map { |x| File.join(LAYOUT_DIR, x) }
      tries.each do |x|
        return x if File.exist?(x)
      end
      return nil
    end

    def initialize
      @layouts = {}
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
