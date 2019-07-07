class Photobook
  class LaTeXPositioner < Positioner

    def document(params, width, height)
      @width, @height = width, height
      puts(<<-EOF)
\\documentclass[12pt]{article}

\\usepackage{geometry}
\\geometry{paperwidth=#{width}bp, paperheight=#{height}bp, margin=0pt}

\\usepackage{graphicx}
\\def\\photobox#1#2#3#4#5{%
  \\vbox to #3{\\vskip 0pt plus #5\\hbox to #2{\\hskip 0pt plus #4%
    \\includegraphics[width=#2,height=#3,keepaspectratio]{#1}%
  \\hfil}\\vfil}%
}
\\def\\backgroundphoto#1#2#3{%
  \\vbox to 0pt{%
    \\hbox{%
      \\includegraphics[bb=0 0 #2 #3,width=#{width}bp, height=#{height}bp]{#1}%
    }%
    \\vss
  }%
}

\\topskip=0pt
\\lineskip=0pt

\\begin{document}

      EOF
      yield

      puts("")
      puts("\\end{document}")
    end

    def insert_background(photo)
      check_photo_name(photo.name)
      w, h = fill_crop(photo, @width, @height)
      puts "\\backgroundphoto{#{photo.name}}{#{w}}{#{h}}%"
    end

    def page(group, margin)
      puts("\\vbox{%")
      insert_background(group.background) if group.background
      puts("\\vskip #{margin}bp\\relax\\moveright #{margin}bp\\hbox{%")
      begin
        @indent = "  "
        yield
      ensure
        @indent = ""
      end
      puts("}}%")
      puts("\\clearpage")
      puts("")
    end

    def box(direction, width, height)
      @indent ||= ""
      case direction
      when :vert then puts("#@indent\\vbox to #{height}bp{%")
      when :horiz then puts("#@indent\\hbox to #{width}bp{%")
      else raise ArgumentError
      end
      begin
        @indent << '  '
        yield
      ensure
        @indent.slice!('  ')
      end
      puts("#@indent}%")
    end

    def space(size, direction)
      dirword = case direction
                when :vert then "\\vskip"
                when :horiz then "\\hskip"
                else raise ArgumentError
                end
      puts("#@indent#{dirword} #{size}bp plus 0.1bp minus 0.1bp\\relax")
    end


    def photo_box(photo, width, height, hgravity, vgravity)
      check_photo_name(photo.name)
      hfill = (hgravity == 1 ? "1fill" : "#{hgravity.to_f / (1 - hgravity)}fil")
      vfill = (vgravity == 1 ? "1fill" : "#{vgravity.to_f / (1 - vgravity)}fil")
      puts(
        "#@indent\\photobox{#{photo.name}}{#{width}bp}{#{height}bp}" +
        "{#{hfill}}{#{vfill}}%"
      )
    end

    def check_photo_name(name)
      if name =~ /\s/
        warn("LaTeX positioner warning: Photo name `#{name}' contains spaces")
      end
    end

  end
end
