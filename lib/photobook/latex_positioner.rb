class Photobook
  class LaTeXPositioner < Positioner

    def document(params, width, height)
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

\\topskip=0pt
\\lineskip=0pt

\\begin{document}

      EOF
      yield

      puts("")
      puts("\\end{document}")
    end

    def page(group, margin)
      puts("\\vbox{\\vskip #{margin}bp\\relax\\moveright #{margin}bp\\hbox{%")
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
      hfill = (hgravity == 1 ? "1fill" : "#{hgravity.to_f / (1 - hgravity)}fil")
      vfill = (vgravity == 1 ? "1fill" : "#{vgravity.to_f / (1 - vgravity)}fil")
      puts(
        "#@indent\\photobox{#{photo.name}}{#{width}bp}{#{height}bp}" +
        "{#{hfill}}{#{vfill}}%"
      )
    end

  end
end
